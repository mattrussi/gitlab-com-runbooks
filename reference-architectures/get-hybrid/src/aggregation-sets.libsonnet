local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';

{
  componentSLIs: aggregationSet.AggregationSet({
    id: 'component',
    name: 'Global Component SLI Metrics',
    intermediateSource: false,
    selector: {},
    labels: ['type', 'component'],
    supportedBurnRates: ['5m', '30m', '1h', '6h'],
    metricFormats: {
      apdexSuccessRate: 'gitlab_component_apdex:success:rate_%s',
      apdexWeight: 'gitlab_component_apdex:weight:score_%s',
      apdexRatio: 'gitlab_component_apdex:ratio_%s',
      opsRate: 'gitlab_component_ops:rate_%s',
      errorRate: 'gitlab_component_errors:rate_%s',
      errorRatio: 'gitlab_component_errors:ratio_%s',
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
    labels: ['type'],
    supportedBurnRates: ['5m', '30m', '1h', '6h'],
    metricFormats: {
      apdexSuccessRate: 'gitlab_service_apdex:success:rate_%s',
      apdexWeight: 'gitlab_service_apdex:weight:score_%s',
      apdexRatio: 'gitlab_service_apdex:ratio_%s',
      opsRate: 'gitlab_service_ops:rate_%s',
      errorRate: 'gitlab_service_errors:rate_%s',
      errorRatio: 'gitlab_service_errors:ratio_%s',
    },
    // Only include components (SLIs) with service_aggregation="yes"
    aggregationFilter: 'service',
  }),


  sidekiqWorkerExecutionSourceSLIs: aggregationSet.AggregationSet({
    id: 'sidekiq_execution',
    name: 'Sidekiq execution source metrics per worker source aggregation',
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
    metricFormats: {
      apdexSuccessRate: 'gitlab_background_jobs:execution:apdex:success:rate_%s',
      apdexWeight: 'gitlab_background_jobs:execution:apdex:weight:score_%s',
      opsRate: 'gitlab_background_jobs:execution:ops:rate_%s',
      errorRate: 'gitlab_background_jobs:execution:error:rate_%s',
    },
  }),

  sidekiqWorkerExecutionSLIs: aggregationSet.AggregationSet({
    id: 'sidekiq_execution',
    name: 'Sidekiq execution source metrics per worker',
    intermediateSource: false,
    selector: { monitor: 'global' },
    labels: [
      'env',
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
    metricFormats: {
      apdexWeight: 'gitlab_background_jobs:execution:apdex:weight:score_%s',
      apdexRatio: 'gitlab_background_jobs:execution:apdex:ratio_%s',
      opsRate: 'gitlab_background_jobs:execution:ops:rate_%s',
      errorRate: 'gitlab_background_jobs:execution:error:rate_%s',
      errorRatio: 'gitlab_background_jobs:execution:error:ratio_%s',
    },
    burnRates: {
      '6h': {
        /* Upscaled */
        apdexRatio: 'gitlab_background_jobs:execution:apdex:ratio_6h',
        opsRate: 'gitlab_background_jobs:execution:ops:rate_6h',
        errorRate: 'gitlab_background_jobs:execution:error:rate_6h',
        errorRatio: 'gitlab_background_jobs:execution:error:ratio_6h',
      },
      '3d': {
        /* Upscaled */
        apdexRatio: 'gitlab_background_jobs:execution:apdex:ratio_3d',
        opsRate: 'gitlab_background_jobs:execution:ops:rate_3d',
        errorRate: 'gitlab_background_jobs:execution:error:rate_6h',
        errorRatio: 'gitlab_background_jobs:execution:error:ratio_3d',
      },
    },
  }),

  /* Note that queue SLIs do not have error rates */
  sidekiqWorkerQueueSourceSLIs: aggregationSet.AggregationSet({
    id: 'sidekiq_queue',
    name: 'Sidekiq queue source metrics per worker source aggregation',
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
    metricFormats: {
      apdexSuccessRate: 'gitlab_background_jobs:queue:apdex:success:rate_%s',
      apdexWeight: 'gitlab_background_jobs:queue:apdex:weight:score_%s',
      opsRate: 'gitlab_background_jobs:queue:ops:rate_%s',
    },
  }),
}
