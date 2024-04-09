local config = import 'gitlab-metrics-config.libsonnet';
local recordingRules = import 'recording-rules/recording-rules.libsonnet';
local intervalForDuration = import 'servicemetrics/interval-for-duration.libsonnet';
local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';

local regionalAggregationSet = aggregationSet.AggregationSet(config.aggregationSets.regionalComponentSLIs {
  // So we only generate these rules for SLIs that are part of the regional aggregation.
  slisForService(serviceDefinition): std.filter(function(sli) sli.regional, serviceDefinition.listServiceLevelIndicators()),

  // So we can calculate the apdex ratio from self rather than relying on the component
  // metrics that in Thanos have the `region` label from the Prometheus aggregation.
  metricFormats+: {
    apdexSuccessRate: 'gitlab_regional_sli_apdex:success:rate_%s',
    apdexWeight: 'gitlab_regional_sli_apdex:weight:score_%s',
  },

  // Record all rates for 3d & 6h, we're using upscaled metrics for that.
  burnRates: {},
});

local outputPromYaml(groups) =
  std.manifestYamlDoc({ groups: groups });

local generatorsForService(aggregationSet, burnRate, extraSelector) = [
  recordingRules.componentMetricsRuleSetGenerator(
    burnRate=burnRate,
    aggregationSet=aggregationSet,
    extraSourceSelector=extraSelector,
  ),
];

local groupsForService(service, aggregationSet, extraSelector) =
  std.map(
    function(burnRate)
      local rules = std.flatMap(
        function(generator)
          generator.generateRecordingRulesForService(service),
        generatorsForService(aggregationSet, burnRate, extraSelector)
      );

      if std.length(rules) > 0 then
        {
          name: '%s: %s - Burn-Rate %s' % [aggregationSet.name, service.type, burnRate],
          partial_response_strategy: 'warn',
          interval: intervalForDuration.intervalForDuration(burnRate),
          rules: rules,
        }
      else {},
    aggregationSet.getBurnRates(),
  );

local aggregationsForService(service, selector) =
  std.foldl(
    function(memo, set)
      local groups = std.prune(groupsForService(service, set, selector));
      if std.length(groups) > 0 then
        memo {
          ['globally-evaluated-%s-aggregation' % set.id]: outputPromYaml(groups),
        }
      else memo,
    [regionalAggregationSet],
    {}
  );

local applicableServices = std.filter(function(service)
  service.dangerouslyThanosEvaluated && service.regional && std.length(service.listServiceLevelIndicators()) > 0, config.monitoredServices);

std.foldl(
  function(memo, service)
    memo + separateGlobalRecordingFiles(
      function(selector)
        aggregationsForService(service, selector),
    ),
  applicableServices,
  {}
)
