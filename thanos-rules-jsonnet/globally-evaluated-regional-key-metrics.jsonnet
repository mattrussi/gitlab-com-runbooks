// This file does not need to be migrated to Mimir. It is a workaround for the
// globally evaluated services in the Thanos+Prometheus environment.
// In that environment, the `region` label that could be present on any source metrics
// will be overridden by the `external_labels` advertised by Prometheus.
//
// This is a problem, becuase some metrics, in the case of AI-gateway, the stackdriver-metrics
// do include a `region` label that is  more accurate than the one from Prometheus.
// For those metrics the information is also present in the `location` label.
//
// Mimir already does this correctly: the `region` external_label will only be added to
// metrics that don't have it. So our strategy in the mimir-aggregation sets when recording this
// from source metrics will work fine.
//
// We can remove this and all of the references to the location aggregation-label in
// https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3398
//
// For more information see https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3398
local config = import 'gitlab-metrics-config.libsonnet';
local aggregationSets = import 'prom-thanos-aggregation-sets.libsonnet';
local recordingRules = import 'recording-rules/recording-rules.libsonnet';
local intervalForDuration = import 'servicemetrics/interval-for-duration.libsonnet';
local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';
local aggregationSetTransformer = import 'servicemetrics/aggregation-set-transformer.libsonnet';

local applicableServices = std.filter(function(service)
  service.dangerouslyThanosEvaluated && service.regional && std.length(service.listServiceLevelIndicators()) > 0, config.monitoredServices);

local regionalAggregationSet = aggregationSet.AggregationSet(aggregationSets.regionalComponentSLIs {
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

local manipulatedRegionalSourceSLIs = aggregationSet.AggregationSet(regionalAggregationSet {
  // Overriding the selector to select global metrics, only for the services that
  // are globally evaluated.
  selector+: { monitor: 'global', type: { oneOf: std.map(function(s) s.type, applicableServices) } },

  // Because we don't want to have the value from `location` in the `region` label if it was
  // present we need to wrap the source expression in this label replace. If we don't we'd use
  // the existing region on the source aggregation, which, in the case of Thanos would
  // be the prometheus instances that scraped the metrics rather than the `location` label of
  // stackdriver.
  wrapSourceExpressionFormat: 'label_replace(%s, "region", "$1", "location", "(.+)")',
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

local defaultsForRecordingRuleGroup = { partial_response_strategy: 'warn' };

local groupsForService(service, aggregationSet, extraSelector) =
  std.map(
    function(burnRate)
      local rules = std.flatMap(
        function(generator)
          generator.generateRecordingRulesForService(service),
        generatorsForService(aggregationSet, burnRate, extraSelector)
      );

      if std.length(rules) > 0 then
        defaultsForRecordingRuleGroup {
          name: '%s: %s - Burn-Rate %s' % [aggregationSet.name, service.type, burnRate],
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

local transformRuleGroups(sourceAggregationSet, targetAggregationSet, extraSourceSelector, extrasForGroup=defaultsForRecordingRuleGroup) =
  aggregationSetTransformer.generateRecordingRuleGroups(
    sourceAggregationSet=sourceAggregationSet { selector+: extraSourceSelector },
    targetAggregationSet=targetAggregationSet,
    extrasForGroup=extrasForGroup,
  );

std.foldl(
  function(memo, service)
    memo + separateGlobalRecordingFiles(
      function(selector)
        aggregationsForService(service, selector),
    ),
  applicableServices,
  {}
)
+
// In Prometheus+Thanos these metrics are also aggregated from the `gitlab_component`
// aggregation set available in ops.
separateGlobalRecordingFiles(
  function(selector)
    {
      'aggregated-globally-evaluated-service-regional-metrics':
        outputPromYaml(
          transformRuleGroups(
            sourceAggregationSet=manipulatedRegionalSourceSLIs,
            targetAggregationSet=aggregationSets.regionalServiceSLIs,
            extraSourceSelector=selector,
          ),
        ),
    }
)
