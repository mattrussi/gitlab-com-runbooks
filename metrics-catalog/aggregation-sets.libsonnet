local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';

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
  promSourceSLIs: aggregationSet.AggregationSet({
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
   * componentSLIs consumes promSourceSLIs and is the primary
   * aggregation used for alerting, monitoring, visualizations, etc.
   */
  componentSLIs: aggregationSet.AggregationSet({
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
   * regionalComponentSLIs consumes promSourceSLIs and is the primary
   * aggregation used for alerting, monitoring, visualizations, etc.
   */
  regionalComponentSLIs: aggregationSet.AggregationSet({
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
   * promSourceNodeComponentSLIs is an source recording rule representing
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
  promSourceNodeComponentSLIs: aggregationSet.AggregationSet({
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
   * nodeComponentSLIs consumes promSourceSLIs and is
   * used for per-node monitoring, alerting, visualzation for Gitaly.
   */
  nodeComponentSLIs: aggregationSet.AggregationSet({
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
        opsRate: 'gitlab_component_node_ops:rate_6h',
        errorRatio: 'gitlab_component_node_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_3d',
        errorRatio: 'gitlab_component_node_errors:ratio_3d',
      },
    },
  }),

  /**
   * serviceSLIs consumes promSourceSLIs and aggregates
   * all the SLIs in a service up to the service level.
   * This is primarily used for visualizations, to give an
   * summary overview of the service. Not used heavily for
   * alerting.
   */
  serviceSLIs: aggregationSet.AggregationSet({
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
   * nodeServiceSLIs consumes nodeComponentSLIs and aggregates
   * all the SLIs in a service up to the service level for each node.
   * This is not particularly useful and should probably be reconsidered
   * at a later stage.
   */
  nodeServiceSLIs: aggregationSet.AggregationSet({
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
  regionalServiceSLIs: aggregationSet.AggregationSet({
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

  sidekiqWorkerExecutionSLIs: aggregationSet.AggregationSet({
    id: 'sidekiq_execution',
    name: 'Sidekiq execution source metrics per worker',
    intermediateSource: true,
    selector: { monitor: { ne: 'global' } },
    labels: [
      'environment',
      'tier',
      'type',
      'stage',
      'shard',
      'queue',
      'feature_category',
      'urgency',
      'worker',
    ],
    burnRates: {
      '1m': {
        apdexWeight: 'gitlab_background_jobs:execution:apdex:weight:score_1m',
        apdexRatio: 'gitlab_background_jobs:execution:apdex:ratio_1m',
        opsRate: 'gitlab_background_jobs:execution:ops:rate_1m',
        errorRate: 'gitlab_background_jobs:execution:error:rate_1m',
        errorRatio: 'gitlab_background_jobs:execution:error:ratio_1m',
      },
      '5m': {
        apdexWeight: 'gitlab_background_jobs:execution:apdex:weight:score_5m',
        apdexRatio: 'gitlab_background_jobs:execution:apdex:ratio_5m',
        opsRate: 'gitlab_background_jobs:execution:ops:rate_5m',
        errorRate: 'gitlab_background_jobs:execution:error:rate_5m',
        errorRatio: 'gitlab_background_jobs:execution:error:ratio_5m',
      },
      '30m': {
        apdexWeight: 'gitlab_background_jobs:execution:apdex:weight:score_30m',
        apdexRatio: 'gitlab_background_jobs:execution:apdex:ratio_30m',
        opsRate: 'gitlab_background_jobs:execution:ops:rate_30m',
        errorRate: 'gitlab_background_jobs:execution:error:rate_30m',
        errorRatio: 'gitlab_background_jobs:execution:error:ratio_30m',
      },
      '1h': {
        apdexWeight: 'gitlab_background_jobs:execution:apdex:weight:score_1h',
        apdexRatio: 'gitlab_background_jobs:execution:apdex:ratio_1h',
        opsRate: 'gitlab_background_jobs:execution:ops:rate_1h',
        errorRate: 'gitlab_background_jobs:execution:error:rate_1h',
        errorRatio: 'gitlab_background_jobs:execution:error:ratio_1h',
      },
      '6h': {
        apdexWeight: 'gitlab_background_jobs:execution:apdex:weight:score_6h',
        apdexRatio: 'gitlab_background_jobs:execution:apdex:ratio_6h',
        opsRate: 'gitlab_background_jobs:execution:ops:rate_6h',
        errorRate: 'gitlab_background_jobs:execution:error:rate_6h',
        errorRatio: 'gitlab_background_jobs:execution:error:ratio_6h',
      },
    },
  }),

  sidekiqWorkerQueueSLIs: aggregationSet.AggregationSet({
    id: 'sidekiq_queue',
    name: 'Sidekiq queue source metrics per worker',
    intermediateSource: true,
    selector: { monitor: { ne: 'global' } },
    labels: [
      'environment',
      'tier',
      'type',
      'stage',
      'shard',
      'queue',
      'feature_category',
      'urgency',
      'worker',
    ],
    burnRates: {
      '1m': {
        apdexWeight: 'gitlab_background_jobs:queue:apdex:weight:score_1m',
        apdexRatio: 'gitlab_background_jobs:queue:apdex:ratio_1m',
        opsRate: 'gitlab_background_jobs:queue:ops:rate_1m',
      },
      '5m': {
        apdexWeight: 'gitlab_background_jobs:queue:apdex:weight:score_5m',
        apdexRatio: 'gitlab_background_jobs:queue:apdex:ratio_5m',
        opsRate: 'gitlab_background_jobs:queue:ops:rate_5m',
      },
      '30m': {
        apdexWeight: 'gitlab_background_jobs:queue:apdex:weight:score_30m',
        apdexRatio: 'gitlab_background_jobs:queue:apdex:ratio_30m',
        opsRate: 'gitlab_background_jobs:queue:ops:rate_30m',
      },
      '1h': {
        apdexWeight: 'gitlab_background_jobs:queue:apdex:weight:score_1h',
        apdexRatio: 'gitlab_background_jobs:queue:apdex:ratio_1h',
        opsRate: 'gitlab_background_jobs:queue:ops:rate_1h',
      },
      '6h': {
        apdexWeight: 'gitlab_background_jobs:queue:apdex:weight:score_6h',
        apdexRatio: 'gitlab_background_jobs:queue:apdex:ratio_6h',
        opsRate: 'gitlab_background_jobs:queue:ops:rate_6h',
      },
    },
  }),

  featureCategorySourceSLIs: aggregationSet.AggregationSet({
    id: 'source_feature_category',
    name: 'Prometheus Source Feature Category Metrics',
    intermediateSource: true,  // Used in dashboards and alerts
    selector: { monitor: { ne: 'global' } },  // Not Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'feature_category'],
    burnRates: {
      '5m': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:success:rate_5m',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_5m',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_5m',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_5m',
      },
      '30m': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:success:rate_30m',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_30m',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_30m',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_30m',
      },
      '1h': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:success:rate_1h',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_1h',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_1h',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_1h',
      },
      '6h': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:success:rate_6h',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_6h',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_6h',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_6h',
      },
    },
  }),

  featureCategorySLIs: aggregationSet.AggregationSet({
    id: 'feature_category',
    name: 'Feature Category Metrics',
    intermediateSource: false,  // Used in dashboards and alerts
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'component', 'feature_category'],
    burnRates: {
      '5m': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:success:rate_5m',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_5m',
        apdexRatio: 'gitlab:component:feature_category:execution:apdex:ratio_5m',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_5m',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_5m',
        errorRatio: 'gitlab:component:feature_category:execution:error:ratio_5m',
      },
      '30m': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:success:rate_30m',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_30m',
        apdexRatio: 'gitlab:component:feature_category:execution:apdex:ratio_30m',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_30m',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_30m',
        errorRatio: 'gitlab:component:feature_category:execution:error:ratio_30m',
      },
      '1h': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:success:rate_1h',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_1h',
        apdexRatio: 'gitlab:component:feature_category:execution:apdex:ratio_1h',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_1h',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_1h',
        errorRatio: 'gitlab:component:feature_category:execution:error:ratio_1h',
      },
      '6h': {
        apdexSuccessRate: 'gitlab:component:feature_category:execution:apdex:success:rate_6h',
        apdexWeight: 'gitlab:component:feature_category:execution:apdex:weight:score_6h',
        apdexRatio: 'gitlab:component:feature_category:execution:apdex:ratio_6h',
        opsRate: 'gitlab:component:feature_category:execution:ops:rate_6h',
        errorRate: 'gitlab:component:feature_category:execution:error:rate_6h',
        errorRatio: 'gitlab:component:feature_category:execution:error:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab:component:feature_category:execution:apdex:ratio_3d',
        errorRatio: 'gitlab:component:feature_category:execution:error:ratio_3d',
      },
    },
  }),

  stageGroupSLIs: aggregationSet.AggregationSet({
    id: 'stage_Groups',
    name: 'Stage Group metrics',
    intermediateSource: false,
    selector: { monitor: 'global' },
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'component', 'stage_group', 'product_stage'],
    joinSource: {
      metric: 'gitlab:feature_category:stage_group:mapping',
      on: 'feature_category',
      labels: ['stage_group', 'product_stage'],
    },
    burnRates: {
      '5m': {
        apdexSuccessRate: 'gitlab:component:stage_group:execution:apdex:success:rate_5m',
        apdexWeight: 'gitlab:component:stage_group:execution:apdex:weight:score_5m',
        apdexRatio: 'gitlab:component:stage_group:execution:apdex:ratio_5m',
        opsRate: 'gitlab:component:stage_group:execution:ops:rate_5m',
        errorRate: 'gitlab:component:stage_group:execution:error:rate_5m',
        errorRatio: 'gitlab:component:stage_group:execution:error:ratio_5m',
      },
      '30m': {
        apdexSuccessRate: 'gitlab:component:stage_group:execution:apdex:success:rate_30m',
        apdexWeight: 'gitlab:component:stage_group:execution:apdex:weight:score_30m',
        apdexRatio: 'gitlab:component:stage_group:execution:apdex:ratio_30m',
        opsRate: 'gitlab:component:stage_group:execution:ops:rate_30m',
        errorRate: 'gitlab:component:stage_group:execution:error:rate_30m',
        errorRatio: 'gitlab:component:stage_group:execution:error:ratio_30m',
      },
      '1h': {
        apdexSuccessRate: 'gitlab:component:stage_group:execution:apdex:success:rate_1h',
        apdexWeight: 'gitlab:component:stage_group:execution:apdex:weight:score_1h',
        apdexRatio: 'gitlab:component:stage_group:execution:apdex:ratio_1h',
        opsRate: 'gitlab:component:stage_group:execution:ops:rate_1h',
        errorRate: 'gitlab:component:stage_group:execution:error:rate_1h',
        errorRatio: 'gitlab:component:stage_group:execution:error:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab:component:stage_group:execution:apdex:ratio_6h',
        errorRatio: 'gitlab:component:stage_group:execution:error:ratio_6h',
      },
    },
  }),
}
