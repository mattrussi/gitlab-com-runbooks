local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'redis-cache',
  tier: 'db',
  serviceIsStageless: true,  // redis-cache does not have a cny stage
  monitoringThresholds: {
    apdexScore: 0.9995,
    errorRatio: 0.999,
  },
  serviceLevelIndicators: {
    rails_redis_client: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_observability',
      description: |||
        Aggregation of all Redis Cache operations issued from the Rails codebase.
      |||,
      significantLabels: ['type'],

      apdex: histogramApdex(
        histogram='gitlab_redis_client_requests_duration_seconds_bucket',
        selector={ storage: 'cache' },
        satisfiedThreshold=0.5,
        toleratedThreshold=0.75,
      ),

      requestRate: rateMetric(
        counter='gitlab_redis_client_requests_total',
        selector={ storage: 'cache' },
      ),

      errorRate: rateMetric(
        counter='gitlab_redis_client_exceptions_total',
        selector={ storage: 'cache' },
      ),
    },

    primary_server: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_observability',
      description: |||
        Operations on the Redis primary for GitLab's caching Redis instance.
      |||,

      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-cache"',
        instanceFilter='redis_instance_info{role="master"}'
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.kibana(title='Redis', index='redis', type='redis-cache'),
        toolingLinks.kibana(title='Redis Slowlog', index='redis_slowlog', type='redis-cache'),
      ],
    },

    secondary_servers: {
      userImpacting: true,  // userImpacting for data redundancy reasons
      featureCategory: 'not_owned',
      team: 'sre_observability',
      description: |||
        Operations on the Redis secondaries for GitLab's caching Redis instance.
      |||,

      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-cache"',
        instanceFilter='redis_instance_info{role="slave"}'
      ),

      significantLabels: ['fqdn'],
      serviceAggregation: false,
    },

    // Rails Cache uses metrics from the main application to guage to performance of the Redis cache
    // This is useful since it's not easy for us to directly calculate an apdex from the Redis metrics
    // directly
    rails_cache: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_observability',
      description: |||
        Rails ActiveSupport Cache operations against the Redis Cache
      |||,

      apdex: histogramApdex(
        histogram='gitlab_cache_operation_duration_seconds_bucket',
        satisfiedThreshold=0.01,
        toleratedThreshold=0.1
      ),

      requestRate: rateMetric(
        counter='gitlab_cache_operation_duration_seconds_count',
      ),

      significantLabels: [],
    },
  },
})
