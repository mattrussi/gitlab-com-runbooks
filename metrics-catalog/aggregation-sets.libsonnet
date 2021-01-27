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
  promSourceSLIs:: aggregationSets.AggregationSet({
    id: 'source_sli',
    name: 'Prometheus Source SLI Metrics',
    selector: { monitor: { ne: 'global' } },  // Not Thanos Ruler
    labels: ['environment', 'tier', 'type', 'stage'],
    burnRates: {
      '1m': {
        apdexRatio: 'gitlab_component_apdex:ratio',
        apdexWeight: 'gitlab_component_apdex:weight:score',
        opsRate: 'gitlab_component_ops:rate',
        errorRate: 'gitlab_component_errors:rate',
        errorRatio: null,
      },
      '5m': {
        apdexRatio: 'gitlab_component_apdex:ratio_5m',
        apdexWeight: 'gitlab_component_apdex:weight:score_5m',
        opsRate: 'gitlab_component_ops:rate_5m',
        errorRate: 'gitlab_component_errors:rate_5m',
        errorRatio: 'gitlab_component_errors:ratio_5m',
      },
      '30m': {
        apdexRatio: 'gitlab_component_apdex:ratio_30m',
        apdexWeight: 'gitlab_component_apdex:weight:score_30m',
        opsRate: 'gitlab_component_ops:rate_30m',
        errorRate: 'gitlab_component_errors:rate_30m',
        errorRatio: 'gitlab_component_errors:ratio_30m',
      },
      '1h': {
        apdexRatio: 'gitlab_component_apdex:ratio_1h',
        apdexWeight: 'gitlab_component_apdex:weight:score_1h',
        opsRate: 'gitlab_component_ops:rate_1h',
        errorRate: 'gitlab_component_errors:rate_1h',
        errorRatio: 'gitlab_component_errors:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab_component_apdex:ratio_6h',
        apdexWeight: 'gitlab_component_apdex:weight:score_6h',
        opsRate: 'gitlab_component_ops:rate_6h',
        errorRate: 'gitlab_component_errors:rate_6h',
        errorRatio: 'gitlab_component_errors:ratio_6h',
      },
    },
  }),

  /**
   * globalSLIs consumes promSourceSLIs and is the primary
   * aggregation used for alerting, monitoring, visualizations, etc.
   */
  globalSLIs:: aggregationSets.AggregationSet({
    id: 'component',
    name: 'Global SLI Metrics',
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
        opsRate: 'gitlab_component_ops:rate_6h',
        errorRate: 'gitlab_component_errors:rate_6h',
        errorRatio: 'gitlab_component_errors:ratio_6h',
      },
    },
  }),

  /**
   * regionalSLIs consumes promSourceSLIs and is the primary
   * aggregation used for alerting, monitoring, visualizations, etc.
   */
  regionalSLIs:: aggregationSets.AggregationSet({
    id: 'regional_component',
    name: 'Regional SLI Metrics',
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
        opsRate: 'gitlab_regional_sli_ops:rate_6h',
        errorRate: 'gitlab_regional_sli_errors:rate_6h',
        errorRatio: 'gitlab_regional_sli_errors:ratio_6h',
      },
    },
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
  promSourceNodeAggregatedSLIs:: aggregationSets.AggregationSet({
    id: 'source_node',
    name: 'Prometheus Source Node-Aggregated SLI Metrics',
    selector: { monitor: { ne: 'global' } },  // Not Thanos Ruler
    labels: ['environment', 'tier', 'type', 'stage', 'shard', 'fqdn', 'component'],
    burnRates: {
      '5m': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_5m',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_5m',
        opsRate: 'gitlab_component_node_ops:rate_5m',
        errorRate: 'gitlab_component_node_errors:rate_5m',
        errorRatio: 'gitlab_component_node_errors:ratio_5m',
      },
      '30m': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_30m',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_30m',
        opsRate: 'gitlab_component_node_ops:rate_30m',
        errorRate: 'gitlab_component_node_errors:rate_30m',
        errorRatio: 'gitlab_component_node_errors:ratio_30m',
      },
      '1h': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_1h',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_1h',
        opsRate: 'gitlab_component_node_ops:rate_1h',
        errorRate: 'gitlab_component_node_errors:rate_1h',
        errorRatio: 'gitlab_component_node_errors:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_6h',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_6h',
        opsRate: 'gitlab_component_node_ops:rate_6h',
        errorRate: 'gitlab_component_node_errors:rate_6h',
        errorRatio: 'gitlab_component_node_errors:ratio_6h',
      },
    },
  }),

  /**
   * globalNodeSLIs consumes promSourceSLIs and is
   * used for per-node monitoring, alerting, visualzation for Gitaly.
   */
  globalNodeSLIs:: aggregationSets.AggregationSet({
    id: 'component_node',
    name: 'Global Node-Aggregated SLI Metrics',
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'shard', 'fqdn', 'component'],
    burnRates: {
      '5m': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_5m',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_5m',  // Required for further aggregation into serviceNodeAggregatedSLIs
        opsRate: 'gitlab_component_node_ops:rate_5m',
        errorRate: 'gitlab_component_node_errors:rate_5m',
        errorRatio: 'gitlab_component_node_errors:ratio_5m',
      },
      '30m': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_30m',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_30m',  // Required for further aggregation into serviceNodeAggregatedSLIs
        opsRate: 'gitlab_component_node_ops:rate_30m',
        errorRate: 'gitlab_component_node_errors:rate_30m',
        errorRatio: 'gitlab_component_node_errors:ratio_30m',
      },
      '1h': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_1h',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_1h',  // Required for further aggregation into serviceNodeAggregatedSLIs
        opsRate: 'gitlab_component_node_ops:rate_1h',
        errorRate: 'gitlab_component_node_errors:rate_1h',
        errorRatio: 'gitlab_component_node_errors:ratio_1h',
      },
      '6h': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_6h',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_6h',  // Required for further aggregation into serviceNodeAggregatedSLIs
        opsRate: 'gitlab_component_node_ops:rate_6h',
        errorRate: 'gitlab_component_node_errors:rate_6h',
        errorRatio: 'gitlab_component_node_errors:ratio_6h',
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
  serviceAggregatedSLIs:: aggregationSets.AggregationSet({
    id: 'service',
    name: 'Global Service-Aggregated Metrics',
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
        opsRate: 'gitlab_service_ops:rate_6h',
        errorRate: 'gitlab_service_errors:rate_6h',
        errorRatio: 'gitlab_service_errors:ratio_6h',
      },
    },
    serviceLevelAggregation: true,
  }),

  /**
   * serviceNodeAggregatedSLIs consumes globalNodeSLIs and aggregates
   * all the SLIs in a service up to the service level for each node.
   * This is not particularly useful and should probably be reconsidered
   * at a later stage.
   */
  serviceNodeAggregatedSLIs:: aggregationSets.AggregationSet({
    id: 'service_node',
    name: 'Global Service-Node-Aggregated Metrics',
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'shard', 'fqdn'],
    burnRates: {
      // No 1m burn rate
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
        opsRate: 'gitlab_service_node_ops:rate_6h',
        errorRate: 'gitlab_service_node_errors:rate_6h',
        errorRatio: 'gitlab_service_node_errors:ratio_6h',
      },
    },
    serviceLevelAggregation: true,
  }),

  /**
   * Regional SLIs, aggregated to the service level
   */
  serviceRegionalAggregatedSLIs:: aggregationSets.AggregationSet({
    id: 'service_regional',
    name: 'Global Service-Regional-Aggregated Metrics',
    selector: { monitor: 'global' },  // Thanos Ruler
    labels: ['env', 'environment', 'tier', 'type', 'stage', 'region'],
    burnRates: {
      // No 1m burn rate
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
        opsRate: 'gitlab_service_regional_ops:rate_6h',
        errorRate: 'gitlab_service_regional_errors:rate_6h',
        errorRatio: 'gitlab_service_regional_errors:ratio_6h',
      },
    },
    serviceLevelAggregation: true,
  }),

}
