local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'redis-ratelimiting',
  tier: 'db',
  serviceIsStageless: true,  // redis-ratelimiting does not have a cny stage

  tags: [
    // redis tag signifies that this service has redis-exporter
    'redis',
  ],

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
        Aggregation of all Redis RateLimit operations issued from the Rails codebase.
      |||,
      significantLabels: ['type'],

      apdex: histogramApdex(
        histogram='gitlab_redis_client_requests_duration_seconds_bucket',
        selector={ storage: 'rate_limiting' },
        satisfiedThreshold=0.5,
        toleratedThreshold=0.75,
      ),

      requestRate: rateMetric(
        counter='gitlab_redis_client_requests_total',
        selector={ storage: 'rate_limiting' },
      ),

      errorRate: rateMetric(
        counter='gitlab_redis_client_exceptions_total',
        selector={ storage: 'rate_limiting' },
      ),
    },

    primary_server: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_observability',
      description: |||
        Operations on the Redis primary for GitLab's rate-limiting Redis instance.
      |||,

      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-ratelimiting"',
        instanceFilter='redis_instance_info{role="master"}'
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.kibana(title='Redis', index='redis', type='redis-ratelimiting'),
        toolingLinks.kibana(title='Redis Slowlog', index='redis_slowlog', type='redis-ratelimiting'),
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
        selector='type="redis-ratelimiting"',
        instanceFilter='redis_instance_info{role="slave"}'
      ),

      significantLabels: ['fqdn'],
      serviceAggregation: false,
    },
  },
})
