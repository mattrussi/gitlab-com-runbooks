local aggregationSet = (import 'servicemetrics/aggregation-set.libsonnet').AggregationSet;

local mimirAggregetionSetDefaults = {
  intermediateSource: false,
  selector: { monitor: 'global' },
  generateSLODashboards: false,
  offset: '30s',
  recordingRuleStaticLabels: {
    // This is to ensure compatibility with the current thanos aggregations.
    // This makes sure that the dashboards would pick these up.
    // When we don't have thanos aggregations anymore, we can remove the selector
    // and static labels from these aggregation sets
    // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2902
    monitor: 'global',
  },
};

{
  componentSLIs: aggregationSet(mimirAggregetionSetDefaults {
    id: 'component',
    name: 'Global SLI Metrics',
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'component'],
    upscaleLongerBurnRates: true,
    metricFormats: {
      apdexWeight: 'gitlab_component_apdex:weight:score_%s',
      apdexSuccessRate: 'gitlab_component_apdex:success:rate_%s',
      apdexRatio: 'gitlab_component_apdex:ratio_%s',
      opsRate: 'gitlab_component_ops:rate_%s',
      errorRate: 'gitlab_component_errors:rate_%s',
      errorRatio: 'gitlab_component_errors:ratio_%s',
    },
  }),

  serviceSLIs: aggregationSet(mimirAggregetionSetDefaults {
    id: 'service',
    name: 'Global Service-Aggregated Metrics',
    labels: ['env', 'environment', 'tier', 'type', 'stage'],
    sourceAggregationSet: $.componentSLIs,
    metricFormats: {
      apdexSuccessRate: 'gitlab_service_apdex:success:rate_%s',
      apdexWeight: 'gitlab_service_apdex:weight:score_%s',
      apdexRatio: 'gitlab_service_apdex:ratio_%s',
      opsRate: 'gitlab_service_ops:rate_%s',
      errorRate: 'gitlab_service_errors:rate_%s',
      errorRatio: 'gitlab_service_errors:ratio_%s',
    },
    aggregationFilter: 'service',
  }),

  nodeComponentSLIs: aggregationSet(mimirAggregetionSetDefaults {
    id: 'component_node',
    name: 'Global Node-Aggregated SLI Metrics',
    intermediateSource: false,
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'shard', 'fqdn', 'component'],
    upscaleLongerBurnRates: true,
    slisForService(serviceDefinition): if serviceDefinition.monitoring.node.enabled then serviceDefinition.listServiceLevelIndicators() else [],
    metricFormats: {
      apdexSuccessRate: 'gitlab_component_node_apdex:success:rate_%s',
      apdexWeight: 'gitlab_component_node_apdex:weight:score_%s',
      apdexRatio: 'gitlab_component_node_apdex:ratio_%s',
      opsRate: 'gitlab_component_node_ops:rate_%s',
      errorRate: 'gitlab_component_node_errors:rate_%s',
      errorRatio: 'gitlab_component_node_errors:ratio_%s',
    },
  }),

  regionalComponentSLIs: aggregationSet(mimirAggregetionSetDefaults {
    id: 'regional_component',
    name: 'Regional SLI Metrics',
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'region', 'component'],
    slisForService(serviceDefinition): std.filter(function(sli) sli.regional, serviceDefinition.listServiceLevelIndicators()),
    upscaleLongerBurnRates: true,
    metricFormats: {
      apdexSuccessRate: 'gitlab_regional_sli_apdex:success:rate_%s',
      apdexWeight: 'gitlab_regional_sli_apdex:weight:score_%s',
      apdexRatio: 'gitlab_regional_sli_apdex:ratio_%s',
      opsRate: 'gitlab_regional_sli_ops:rate_%s',
      errorRate: 'gitlab_regional_sli_errors:rate_%s',
      errorRatio: 'gitlab_regional_sli_errors:ratio_%s',
    },
  }),

  aggregationsFromSource::
    std.filter(
      function(aggregationSet)
        aggregationSet.sourceAggregationSet == null,
      std.objectValues(self)
    ),

  transformedAggregations::
    std.filter(
      function(aggregationSet)
        aggregationSet.sourceAggregationSet != null,
      std.objectValues(self)
    ),
}
