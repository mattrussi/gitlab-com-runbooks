local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'redis-sidekiq',
  tier: 'db',
  serviceIsStageless: true,  // redis-sidekiq does not have a cny stage

  tags: [
    // redis tag signifies that this service has redis-exporter
    'redis',
  ],

  monitoringThresholds: {
    apdexScore: 0.9999,
    errorRatio: 0.999,
  },
  serviceLevelIndicators: {
    rails_redis_client: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        Aggregation of all Redis operations issued to the Redis Sidekiq service from the Rails codebase.

        If this SLI is experiencing a degradation, it may be caused by saturation in the Redis Sidekiq instance caused by
        high traffic volumes from Sidekiq clients (Rails or other sidekiq jobs), or very large messages being delivered
        via Sidekiq.

        Reviewing Sidekiq job logs may help the investigation.
      |||,
      significantLabels: ['type'],

      apdex: histogramApdex(
        histogram='gitlab_redis_client_requests_duration_seconds_bucket',
        selector={ storage: 'queues' },
        satisfiedThreshold=0.5,
        toleratedThreshold=0.75,
      ),

      requestRate: rateMetric(
        counter='gitlab_redis_client_requests_total',
        selector={ storage: 'queues' },
      ),

      errorRate: rateMetric(
        counter='gitlab_redis_client_exceptions_total',
        selector={ storage: 'queues' },
      ),
    },

    primary_server: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        Operations on the Redis primary for GitLab's persistent Redis instance.
      |||,

      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-sidekiq"',
        instanceFilter='redis_instance_info{role="master"}'
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.kibana(title='Redis', index='redis', type='redis-sidekiq'),
        toolingLinks.kibana(title='Redis Slowlog', index='redis_slowlog', type='redis-sidekiq'),
      ],
    },
    secondary_servers: {
      userImpacting: true,  // userImpacting for data redundancy reasons
      featureCategory: 'not_owned',
      description: |||
        Operations on the Redis secondaries for GitLab's persistent Redis instance.
      |||,

      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-sidekiq"',
        instanceFilter='redis_instance_info{role="slave"}'
      ),

      significantLabels: ['fqdn'],
      serviceAggregation: false,
    },
  },
})
