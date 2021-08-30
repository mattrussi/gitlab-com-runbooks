local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'redis-tracechunks',
  tier: 'db',
  serviceIsStageless: true,  // redis-tracechunks does not have a cny stage
  monitoringThresholds: {
    apdexScore: 0.9999,
    errorRatio: 0.999,
  },
  serviceLevelIndicators: {
    rails_redis_client: {
      userImpacting: true,
      featureCategory: 'continuous_integration',
      team: 'sre_observability',
      description: |||
        Aggregation of all Redis operations issued to the Redis Tracechunks service from the Rails codebase.

        If this SLI is experiencing a degradation then the output of CI jobs may be delayed in becoming visible
        or in severe situations the data may be lost
      |||,
      significantLabels: ['type'],

      apdex: histogramApdex(
        histogram='gitlab_redis_client_requests_duration_seconds_bucket',
        selector={ storage: 'tracechunks' },
        satisfiedThreshold=0.5,
        toleratedThreshold=0.75,
      ),

      requestRate: rateMetric(
        counter='gitlab_redis_client_requests_total',
        selector={ storage: 'tracechunks' },
      ),

      errorRate: rateMetric(
        counter='gitlab_redis_client_exceptions_total',
        selector={ storage: 'tracechunks' },
      ),
    },

    primary_server: {
      userImpacting: true,
      featureCategory: 'continuous_integration',
      team: 'sre_observability',
      description: |||
        Operations on the Redis primary for GitLab's Redis Tracechunks instance.
      |||,

      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-tracechunks"',
        instanceFilter='redis_instance_info{role="master"}'
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.kibana(title='Redis', index='redis', type='redis-tracechunks'),
      ],
    },
    secondary_servers: {
      userImpacting: true,  // userImpacting for data redundancy reasons
      featureCategory: 'continuous_integration',
      team: 'sre_observability',
      description: |||
        Operations on the Redis secondaries for GitLab's Redis Tracechunks instance.
      |||,

      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-tracechunks"',
        instanceFilter='redis_instance_info{role="slave"}'
      ),

      significantLabels: ['fqdn'],
      serviceAggregation: false,
    },
  },
})
