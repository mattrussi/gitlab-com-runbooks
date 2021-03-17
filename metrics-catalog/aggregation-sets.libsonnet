local aggregationSets = import 'servicemetrics/aggregation-set.libsonnet';

{
  /**
   * promSourceSLIs is an intermediate recording rule representing
   * the "start" of the aggregation pipeline.
   * It collects "raw" source metrics in a prometheus instance and
   * aggregates them, reducing cardinality, before
   * these values are used downstream in Thanos.
   *
   * Should not be used directly for alerting or visualization as it
   * only represents the view from a single prometheus instance,
   * not globally across all shards.
   */
  promSourceSLIs: aggregationSets.AggregationSet({
    id: 'source_sli',
    name: 'Prometheus Source SLI Metrics',
    intermediateSource: true,  // Not intended for consumption in dashboards or alerts
    selector: { monitor: { ne: 'global' } },  // Not Thanos Ruler
    labels: ['environment', 'tier', 'type', 'stage'],
    burnRates: {
      '1m': {
        apdexSuccessRate: 'gitlab_component_apdex:success:rate',
        apdexWeight: 'gitlab_component_apdex:weight:score',
        opsRate: 'gitlab_component_ops:rate',
        errorRate: 'gitlab_component_errors:rate',
      },
      '5m': {
        apdexSuccessRate: 'gitlab_component_apdex:success:rate_5m',
        apdexWeight: 'gitlab_component_apdex:weight:score_5m',
        opsRate: 'gitlab_component_ops:rate_5m',
        errorRate: 'gitlab_component_errors:rate_5m',
      },
      '30m': {
        apdexSuccessRate: 'gitlab_component_apdex:success:rate_30m',
        apdexWeight: 'gitlab_component_apdex:weight:score_30m',
        opsRate: 'gitlab_component_ops:rate_30m',
        errorRate: 'gitlab_component_errors:rate_30m',
      },
      '1h': {
        apdexSuccessRate: 'gitlab_component_apdex:success:rate_1h',
        apdexWeight: 'gitlab_component_apdex:weight:score_1h',
        opsRate: 'gitlab_component_ops:rate_1h',
        errorRate: 'gitlab_component_errors:rate_1h',
      },
      '6h': {
        apdexSuccessRate: 'gitlab_component_apdex:success:rate_6h',
        apdexWeight: 'gitlab_component_apdex:weight:score_6h',
        opsRate: 'gitlab_component_ops:rate_6h',
        errorRate: 'gitlab_component_errors:rate_6h',
      },
    },
  }),

  /**
   * globalSLIs consumes promSourceSLIs and is the primary
   * aggregation used for alerting, monitoring, visualizations, etc.
   */
  globalSLIs: aggregationSets.AggregationSet({
    id: 'component',
    name: 'Global SLI Metrics',
    intermediateSource: false,  // Used in dashboards and alerts
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'component'],
    burnRates: {
      '1m': {
        apdexRatio: 'gitlab_component_apdex:ratio',
        opsRate: 'gitlab_component_ops:rate',
        errorRate: 'gitlab_component_errors:rate',
        errorRatio: 'gitlab_component_errors:ratio',
      },
      '5m': {
        apdexRatio: 'gitlab_component_apdex:ratio_5m',
        opsRate: 'gitlab_component_ops:rate_5m',
        errorRate: 'gitlab_component_errors:rate_5m',
        errorRatio: 'gitlab_component_errors:ratio_5m',
      },
      '30m': {
        apdexRatio: 'gitlab_component_apdex:ratio_30m',
        opsRate: 'gitlab_component_ops:rate_30m',
        errorRate: 'gitlab_component_errors:rate_30m',
        errorRatio: 'gitlab_component_errors:ratio_30m',
      },
      '1h': {
        apdexRatio: 'gitlab_component_apdex:ratio_1h',
        opsRate: 'gitlab_component_ops:rate_1h',
        errorRate: 'gitlab_component_errors:rate_1h',
        errorRatio: 'gitlab_component_errors:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab_component_apdex:ratio_6h',
        errorRatio: 'gitlab_component_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_component_apdex:ratio_3d',
        errorRatio: 'gitlab_component_errors:ratio_3d',
      },
    },
  }),

  /**
   * regionalSLIs consumes promSourceSLIs and is the primary
   * aggregation used for alerting, monitoring, visualizations, etc.
   */
  regionalSLIs: aggregationSets.AggregationSet({
    id: 'regional_component',
    name: 'Regional SLI Metrics',
    intermediateSource: false,  // Used in dashboards and alerts
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'region', 'component'],
    burnRates: {
      '5m': {
        apdexRatio: 'gitlab_regional_sli_apdex:ratio_5m',
        opsRate: 'gitlab_regional_sli_ops:rate_5m',
        errorRate: 'gitlab_regional_sli_errors:rate_5m',
        errorRatio: 'gitlab_regional_sli_errors:ratio_5m',
      },
      '30m': {
        apdexRatio: 'gitlab_regional_sli_apdex:ratio_30m',
        opsRate: 'gitlab_regional_sli_ops:rate_30m',
        errorRate: 'gitlab_regional_sli_errors:rate_30m',
        errorRatio: 'gitlab_regional_sli_errors:ratio_30m',
      },
      '1h': {
        apdexRatio: 'gitlab_regional_sli_apdex:ratio_1h',
        opsRate: 'gitlab_regional_sli_ops:rate_1h',
        errorRate: 'gitlab_regional_sli_errors:rate_1h',
        errorRatio: 'gitlab_regional_sli_errors:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab_regional_sli_apdex:ratio_6h',
        errorRatio: 'gitlab_regional_sli_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_regional_sli_apdex:ratio_3d',
        errorRatio: 'gitlab_regional_sli_errors:ratio_3d',
      },
    },
    // Only include components (SLIs) with regional_aggregation="yes"
    aggregationFilter: 'regional',
  }),

  /**
   * promSourceNodeAggregatedSLIs is an source recording rule representing
   * the "start" of the aggregation pipeline for per-node aggregations,
   * used by Gitaly.
   *
   * It collects "raw" source metrics in a prometheus instance and
   * aggregates them, reducing cardinality, before
   * these values are used downstream in Thanos.
   *
   * Should not be used directly for alerting or visualization as it
   * only represents the view from a single prometheus instance,
   * not globally across all shards.
   */
  promSourceNodeAggregatedSLIs: aggregationSets.AggregationSet({
    id: 'source_node',
    name: 'Prometheus Source Node-Aggregated SLI Metrics',
    intermediateSource: true,  // Not intended for consumption in dashboards or alerts
    selector: { monitor: { ne: 'global' } },  // Not Thanos Ruler
    labels: ['environment', 'tier', 'type', 'stage', 'shard', 'fqdn', 'component'],
    burnRates: {
      '5m': {
        apdexSuccessRate: 'gitlab_component_node_apdex:success:rate_5m',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_5m',
        opsRate: 'gitlab_component_node_ops:rate_5m',
        errorRate: 'gitlab_component_node_errors:rate_5m',
      },
      '30m': {
        apdexSuccessRate: 'gitlab_component_node_apdex:success:rate_30m',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_30m',
        opsRate: 'gitlab_component_node_ops:rate_30m',
        errorRate: 'gitlab_component_node_errors:rate_30m',
      },
      '1h': {
        apdexSuccessRate: 'gitlab_component_node_apdex:success:rate_1h',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_1h',
        opsRate: 'gitlab_component_node_ops:rate_1h',
        errorRate: 'gitlab_component_node_errors:rate_1h',
        errorRatio: 'gitlab_component_node_errors:ratio_1h',
      },
      '6h': {
        apdexSuccessRate: 'gitlab_component_node_apdex:success:rate_6h',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_6h',
        opsRate: 'gitlab_component_node_ops:rate_6h',
        errorRate: 'gitlab_component_node_errors:rate_6h',
      },
    },
  }),

  /**
   * globalNodeSLIs consumes promSourceSLIs and is
   * used for per-node monitoring, alerting, visualzation for Gitaly.
   */
  globalNodeSLIs: aggregationSets.AggregationSet({
    id: 'component_node',
    name: 'Global Node-Aggregated SLI Metrics',
    intermediateSource: false,  // Used in dashboards and alerts
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'shard', 'fqdn', 'component'],
    burnRates: {
      '5m': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_5m',
        opsRate: 'gitlab_component_node_ops:rate_5m',
        errorRate: 'gitlab_component_node_errors:rate_5m',
        errorRatio: 'gitlab_component_node_errors:ratio_5m',
      },
      '30m': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_30m',
        opsRate: 'gitlab_component_node_ops:rate_30m',
        errorRate: 'gitlab_component_node_errors:rate_30m',
        errorRatio: 'gitlab_component_node_errors:ratio_30m',
      },
      '1h': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_1h',
        opsRate: 'gitlab_component_node_ops:rate_1h',
        errorRate: 'gitlab_component_node_errors:rate_1h',
        errorRatio: 'gitlab_component_node_errors:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_6h',
        errorRatio: 'gitlab_component_node_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_3d',
        errorRatio: 'gitlab_component_node_errors:ratio_3d',
      },
    },
  }),

  /**
   * globalNodeSLIs consumes promSourceSLIs and aggregates
   * all the SLIs in a service up to the service level.
   * This is primarily used for visualizations, to give an
   * summary overview of the service. Not used heavily for
   * alerting.
   */
  serviceAggregatedSLIs: aggregationSets.AggregationSet({
    id: 'service',
    name: 'Global Service-Aggregated Metrics',
    intermediateSource: false,  // Used in dashboards and alerts
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage'],
    burnRates: {
      '1m': {
        apdexRatio: 'gitlab_service_apdex:ratio',
        opsRate: 'gitlab_service_ops:rate',
        errorRate: 'gitlab_service_errors:rate',
        errorRatio: 'gitlab_service_errors:ratio',
      },
      '5m': {
        apdexRatio: 'gitlab_service_apdex:ratio_5m',
        opsRate: 'gitlab_service_ops:rate_5m',
        errorRate: 'gitlab_service_errors:rate_5m',
        errorRatio: 'gitlab_service_errors:ratio_5m',
      },
      '30m': {
        apdexRatio: 'gitlab_service_apdex:ratio_30m',
        opsRate: 'gitlab_service_ops:rate_30m',
        errorRate: 'gitlab_service_errors:rate_30m',
        errorRatio: 'gitlab_service_errors:ratio_30m',
      },
      '1h': {
        apdexRatio: 'gitlab_service_apdex:ratio_1h',
        opsRate: 'gitlab_service_ops:rate_1h',
        errorRate: 'gitlab_service_errors:rate_1h',
        errorRatio: 'gitlab_service_errors:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab_service_apdex:ratio_6h',
        errorRatio: 'gitlab_service_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_service_apdex:ratio_3d',
        errorRatio: 'gitlab_service_errors:ratio_3d',
      },
    },
    // Only include components (SLIs) with service_aggregation="yes"
    aggregationFilter: 'service',
  }),

  /**
   * serviceNodeAggregatedSLIs consumes globalNodeSLIs and aggregates
   * all the SLIs in a service up to the service level for each node.
   * This is not particularly useful and should probably be reconsidered
   * at a later stage.
   */
  serviceNodeAggregatedSLIs: aggregationSets.AggregationSet({
    id: 'service_node',
    name: 'Global Service-Node-Aggregated Metrics',
    intermediateSource: false,  // Used in dashboards and alerts
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'shard', 'fqdn'],
    burnRates: {
      '5m': {
        apdexRatio: 'gitlab_service_node_apdex:ratio_5m',
        opsRate: 'gitlab_service_node_ops:rate_5m',
        errorRate: 'gitlab_service_node_errors:rate_5m',
        errorRatio: 'gitlab_service_node_errors:ratio_5m',
      },
      '30m': {
        apdexRatio: 'gitlab_service_node_apdex:ratio_30m',
        opsRate: 'gitlab_service_node_ops:rate_30m',
        errorRate: 'gitlab_service_node_errors:rate_30m',
        errorRatio: 'gitlab_service_node_errors:ratio_30m',
      },
      '1h': {
        apdexRatio: 'gitlab_service_node_apdex:ratio_1h',
        opsRate: 'gitlab_service_node_ops:rate_1h',
        errorRate: 'gitlab_service_node_errors:rate_1h',
        errorRatio: 'gitlab_service_node_errors:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab_service_node_apdex:ratio_6h',
        errorRatio: 'gitlab_service_node_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_service_node_apdex:ratio_3d',
        errorRatio: 'gitlab_service_node_errors:ratio_3d',
      },
    },
    // Only include components (SLIs) with service_aggregation="yes"
    aggregationFilter: 'service',
  }),

  /**
   * Regional SLIs, aggregated to the service level
   */
  serviceRegionalAggregatedSLIs: aggregationSets.AggregationSet({
    id: 'service_regional',
    name: 'Global Service-Regional-Aggregated Metrics',
    intermediateSource: false,  // Used in dashboards and alerts
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'region'],
    burnRates: {
      '5m': {
        apdexRatio: 'gitlab_service_regional_apdex:ratio_5m',
        opsRate: 'gitlab_service_regional_ops:rate_5m',
        errorRate: 'gitlab_service_regional_errors:rate_5m',
        errorRatio: 'gitlab_service_regional_errors:ratio_5m',
      },
      '30m': {
        apdexRatio: 'gitlab_service_regional_apdex:ratio_30m',
        opsRate: 'gitlab_service_regional_ops:rate_30m',
        errorRate: 'gitlab_service_regional_errors:rate_30m',
        errorRatio: 'gitlab_service_regional_errors:ratio_30m',
      },
      '1h': {
        apdexRatio: 'gitlab_service_regional_apdex:ratio_1h',
        opsRate: 'gitlab_service_regional_ops:rate_1h',
        errorRate: 'gitlab_service_regional_errors:rate_1h',
        errorRatio: 'gitlab_service_regional_errors:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab_service_regional_apdex:ratio_6h',
        errorRatio: 'gitlab_service_regional_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_service_regional_apdex:ratio_3d',
        errorRatio: 'gitlab_service_regional_errors:ratio_3d',
      },
    },
    // Only include components (SLIs) with regional_aggregation="yes"
    aggregationFilter: 'regional',
  }),

  featureCategorySourceSLIs: aggregationSets.AggregationSet({
    id: 'source_feature_category',
    name: 'Prometheus Source Feature Category Metrics',
    intermediateSource: true,  // Used in dashboards and alerts
    selector: { monitor: { ne: 'global' } },  // Not Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'component', 'feature_category'],
    burnRates: {
      '5m': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:weight:score_5m',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_5m',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_5m',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_5m',
      },
      '30m': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:weight:score_30m',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_30m',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_30m',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_30m',
      },
      '1h': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:weight:score_1h',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_1h',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_1h',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_1h',
      },
      '6h': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:weight:score_6h',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_6h',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_6h',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_6h',
      },
    },
  }),

  globalFeatureCategorySLIs: aggregationSets.AggregationSet({
    id: 'feature_category',
    name: 'Feature Category Metrics',
    intermediateSource: false,  // Used in dashboards and alerts
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'component', 'feature_category'],
    burnRates: {
      '5m': {
        apdexRatio: 'gitlab:component:feature_category:execution:apdex:ratio_5m',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_5m',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_5m',
        errorRatio: 'gitlab:component:feature_category:execution:error:ratio_5m',
      },
      '30m': {
        apdexRatio: 'gitlab:component:feature_category:execution:apdex:ratio_30m',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_30m',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_30m',
        errorRatio: 'gitlab:component:feature_category:execution:error:ratio_30m',
      },
      '1h': {
        apdexRatio: 'gitlab:component:feature_category:execution:apdex:ratio_1h',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_1h',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_1h',
        errorRatio: 'gitlab:component:feature_category:execution:error:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab:component:feature_category:execution:apdex:ratio_6h',
        errorRatio: 'gitlab:component:feature_category:execution:error:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab:component:feature_category:execution:apdex:ratio_3d',
        errorRatio: 'gitlab:component:feature_category:execution:error:ratio_3d',
      },
    },
  }),
}
