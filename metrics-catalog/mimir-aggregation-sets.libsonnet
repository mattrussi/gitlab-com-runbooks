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
      // Recording ratios from source metrics (here SLI-aggregations) is not yet
      // supported in the `componentMetricsRuleSetGenerator`. We'll need to add support for those
      // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2899
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
}
