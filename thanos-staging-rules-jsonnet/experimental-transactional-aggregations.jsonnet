local AggregationSet = (import 'servicemetrics/aggregation-set.libsonnet').AggregationSet;
local separateGlobalRecordingRuleFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;
local metricsConfig = import 'gitlab-metrics-config.libsonnet';
local intervalForDuration = import 'servicemetrics/interval-for-duration.libsonnet';
local recordingRules = import 'recording-rules/recording-rules.libsonnet';

// Some source aggregation sets based on the ones we already have. These are rules
// That primarily live in Prometheus now
local componentSLIs = AggregationSet({
  id: 'component_slis',
  name: 'Service Component SLIs',
  intermediateSource: false,  // As this is evaluated in thanos, we don't need anything intermediate
  selector: {},  // If we ever need a way to select for this
  labels: ['env', 'environment', 'tier', 'type', 'stage'],  // The component is a static label
  offset: '10s',
  metricFormats: {
    apdexSuccessRate: 'experimental:gitlab_component_apdex:success:rate_%s',
    apdexWeight: 'experimental:gitlab_component_apdex:weight:score_%s',
    apdexRates: 'experimental:gitlab_component_apdex:rates_%s',
    opsRate: 'experimental:gitlab_component_ops:rate_%s',
    errorRate: 'experimental:gitlab_component_errors:rate_%s',
    errorRates: 'experimental:gitlab_component_errors:rates_%s',
    // TODO: record ratio from source metrics
  },
});

local outputPromYaml(groups, groupExtras) =
  std.manifestYamlDoc({
    groups: [
      groupExtras + group
      for group in groups
    ],
  });

// This is a very limited implementation of prometheus-service-group-generator.libsonnet because we _just_ want
// aggregation set metrics here, no filtering, no shard/node aggregations and what not.
// All the rules except feature category ones in the `prometheus-service-group-generator.libsonnet` (evaluated in prometheus)
// are currently added to the same rule-group. This is likely going to be a bottleneck
// if we move everything to thanos. We're better off with a rule-group per aggregation.
// It's likely that we can split them all into separate files, so we can easily shard
// them across thanos rulers.
local recordingRuleGroup(aggregationSet, service, burnRate, extraSelector) = {
  name: '%s: %s - %s burn-rate' % [aggregationSet.name, service.type, burnRate],
  interval: intervalForDuration.intervalForDuration(burnRate),
  rules: recordingRules.componentMetricsRuleSetGenerator(
    burnRate=burnRate, aggregationSet=aggregationSet { selector+: extraSelector }
  ).generateRecordingRulesForService(service),
};


local filesForService(service, aggregationSet, extraSelector) =
  {
    ['%s/key-metrics' % [service.type]]:
      outputPromYaml(
        [
          recordingRuleGroup(aggregationSet, service, burnRate, extraSelector)
          for burnRate in aggregationSet.getBurnRates()
        ],
        { partial_response_strategy: 'abort' }
      ),
  };

local testServices = std.filter(
  function(s) std.member(['web', 'api', 'gitaly', 'sidekiq'], s.type),
  metricsConfig.monitoredServices
);
std.foldl(
  function(memo, service)
    memo + separateGlobalRecordingRuleFiles(
      function(selector)
        filesForService(service, componentSLIs, selector),
      pathFormat='experimental/%(envName)s/%(baseName)s.yml'
    )
  , testServices, {}
)
