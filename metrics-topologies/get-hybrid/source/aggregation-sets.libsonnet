local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';

{
  componentSLIs: aggregationSet.AggregationSet({
    id: 'component',
    name: 'Global SLI Metrics',
    intermediateSource: false,
    selector: {},
    labels: ['type', 'component'],
    burnRates: {
      '5m': {
        apdexSuccessRate: 'gitlab_component_apdex:success:rate_5m',
        apdexWeight: 'gitlab_component_apdex:weight:score_5m',
        apdexRatio: 'gitlab_component_apdex:ratio_5m',
        opsRate: 'gitlab_component_ops:rate_5m',
        errorRate: 'gitlab_component_errors:rate_5m',
        errorRatio: 'gitlab_component_errors:ratio_5m',
      },
      '30m': {
        apdexSuccessRate: 'gitlab_component_apdex:success:rate_30m',
        apdexWeight: 'gitlab_component_apdex:weight:score_30m',
        apdexRatio: 'gitlab_component_apdex:ratio_30m',
        opsRate: 'gitlab_component_ops:rate_30m',
        errorRate: 'gitlab_component_errors:rate_30m',
        errorRatio: 'gitlab_component_errors:ratio_30m',
      },
      '1h': {
        apdexSuccessRate: 'gitlab_component_apdex:success:rate_1h',
        apdexWeight: 'gitlab_component_apdex:weight:score_1h',
        apdexRatio: 'gitlab_component_apdex:ratio_1h',
        opsRate: 'gitlab_component_ops:rate_1h',
        errorRate: 'gitlab_component_errors:rate_1h',
        errorRatio: 'gitlab_component_errors:ratio_1h',
      },
      '6h': {
        apdexSuccessRate: 'gitlab_component_apdex:success:rate_6h',
        apdexWeight: 'gitlab_component_apdex:weight:score_6h',
        apdexRatio: 'gitlab_component_apdex:ratio_6h',
        opsRate: 'gitlab_component_ops:rate_6h',
        errorRate: 'gitlab_component_errors:rate_6h',
        errorRatio: 'gitlab_component_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_component_apdex:ratio_6h',
        errorRatio: 'gitlab_component_errors:ratio_6h',
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
    intermediateSource: false,
    selector: {},
    labels: ['type', 'component', 'node'],
    burnRates: {
      '5m': {
        apdexSuccessRate: 'gitlab_component_node_apdex:success:rate_5m',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_5m',
        apdexRatio: 'gitlab_component_node_apdex:ratio_5m',
        opsRate: 'gitlab_component_node_ops:rate_5m',
        errorRate: 'gitlab_component_node_errors:rate_5m',
        errorRatio: 'gitlab_component_node_errors:ratio_5m',
      },
      '30m': {
        apdexSuccessRate: 'gitlab_component_node_apdex:success:rate_30m',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_30m',
        apdexRatio: 'gitlab_component_node_apdex:ratio_30m',
        opsRate: 'gitlab_component_node_ops:rate_30m',
        errorRate: 'gitlab_component_node_errors:rate_30m',
        errorRatio: 'gitlab_component_node_errors:ratio_30m',
      },
      '1h': {
        apdexSuccessRate: 'gitlab_component_node_apdex:success:rate_1h',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_1h',
        apdexRatio: 'gitlab_component_node_apdex:ratio_1h',
        opsRate: 'gitlab_component_node_ops:rate_1h',
        errorRate: 'gitlab_component_node_errors:rate_1h',
        errorRatio: 'gitlab_component_node_errors:ratio_1h',
      },
      '6h': {
        apdexSuccessRate: 'gitlab_component_node_apdex:success:rate_6h',
        apdexWeight: 'gitlab_component_node_apdex:weight:score_6h',
        apdexRatio: 'gitlab_component_node_apdex:ratio_6h',
        opsRate: 'gitlab_component_node_ops:rate_6h',
        errorRate: 'gitlab_component_node_errors:rate_6h',
        errorRatio: 'gitlab_component_node_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_component_node_apdex:ratio_6h',
        errorRatio: 'gitlab_component_node_errors:ratio_6h',
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
    intermediateSource: false,
    selector: {},
    labels: ['type', 'component', 'node'],
    burnRates: {
      '5m': {
        apdexSuccessRate: 'gitlab_service_apdex:success:rate_5m',
        apdexWeight: 'gitlab_service_apdex:weight:score_5m',
        apdexRatio: 'gitlab_service_apdex:ratio_5m',
        opsRate: 'gitlab_service_ops:rate_5m',
        errorRate: 'gitlab_service_errors:rate_5m',
        errorRatio: 'gitlab_service_errors:ratio_5m',
      },
      '30m': {
        apdexSuccessRate: 'gitlab_service_apdex:success:rate_30m',
        apdexWeight: 'gitlab_service_apdex:weight:score_30m',
        apdexRatio: 'gitlab_service_apdex:ratio_30m',
        opsRate: 'gitlab_service_ops:rate_30m',
        errorRate: 'gitlab_service_errors:rate_30m',
        errorRatio: 'gitlab_service_errors:ratio_30m',
      },
      '1h': {
        apdexSuccessRate: 'gitlab_service_apdex:success:rate_1h',
        apdexWeight: 'gitlab_service_apdex:weight:score_1h',
        apdexRatio: 'gitlab_service_apdex:ratio_1h',
        opsRate: 'gitlab_service_ops:rate_1h',
        errorRate: 'gitlab_service_errors:rate_1h',
        errorRatio: 'gitlab_service_errors:ratio_1h',
      },
      '6h': {
        apdexSuccessRate: 'gitlab_service_apdex:success:rate_6h',
        apdexWeight: 'gitlab_service_apdex:weight:score_6h',
        apdexRatio: 'gitlab_service_apdex:ratio_6h',
        opsRate: 'gitlab_service_ops:rate_6h',
        errorRate: 'gitlab_service_errors:rate_6h',
        errorRatio: 'gitlab_service_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_service_apdex:ratio_6h',
        errorRatio: 'gitlab_service_errors:ratio_6h',
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
    selector: {},  // Thanos Ruler
    labels: ['type', 'node'],
    burnRates: {
      '5m': {
        apdexSuccessRate: 'gitlab_service_node_apdex:success:rate_5m',
        apdexWeight: 'gitlab_service_node_apdex:weight:score_5m',
        apdexRatio: 'gitlab_service_node_apdex:ratio_5m',
        opsRate: 'gitlab_service_node_ops:rate_5m',
        errorRate: 'gitlab_service_node_errors:rate_5m',
        errorRatio: 'gitlab_service_node_errors:ratio_5m',
      },
      '30m': {
        apdexSuccessRate: 'gitlab_service_node_apdex:success:rate_30m',
        apdexWeight: 'gitlab_service_node_apdex:weight:score_30m',
        apdexRatio: 'gitlab_service_node_apdex:ratio_30m',
        opsRate: 'gitlab_service_node_ops:rate_30m',
        errorRate: 'gitlab_service_node_errors:rate_30m',
        errorRatio: 'gitlab_service_node_errors:ratio_30m',
      },
      '1h': {
        apdexSuccessRate: 'gitlab_service_node_apdex:success:rate_1h',
        apdexWeight: 'gitlab_service_node_apdex:weight:score_1h',
        apdexRatio: 'gitlab_service_node_apdex:ratio_1h',
        opsRate: 'gitlab_service_node_ops:rate_1h',
        errorRate: 'gitlab_service_node_errors:rate_1h',
        errorRatio: 'gitlab_service_node_errors:ratio_1h',
      },
      '6h': {
        apdexSuccessRate: 'gitlab_service_node_apdex:success:rate_6h',
        apdexWeight: 'gitlab_service_node_apdex:weight:score_6h',
        apdexRatio: 'gitlab_service_node_apdex:ratio_6h',
        opsRate: 'gitlab_service_node_ops:rate_6h',
        errorRate: 'gitlab_service_node_errors:rate_6h',
        errorRatio: 'gitlab_service_node_errors:ratio_6h',
      },
      '3d': {
        apdexRatio: 'gitlab_service_node_apdex:ratio_6h',
        errorRatio: 'gitlab_service_node_errors:ratio_6h',
      },
    },
    // Only include components (SLIs) with service_aggregation="yes"
    aggregationFilter: 'service',
  }),
}
