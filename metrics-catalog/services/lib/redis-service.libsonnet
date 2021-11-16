local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

{
  redisServiceDefinition(
    name='',
    descriptiveName,
    otherSlis={},
    featureCategory='not_owned',
    storage,
    monitoringThresholds={
      apdexScore: 0.9995,
      errorRatio: 0.999,
    },
    additionalSLIText=''
  )::
    local redisName = if name != '' then 'redis-%s' % name else 'redis';

    metricsCatalog.serviceDefinition({
      type: redisName,
      tier: 'db',
      serviceIsStageless: true,  // Redis does not have a cny stage

      tags: [
        // redis tag signifies that this service has redis-exporter
        'redis',
      ],

      monitoringThresholds: monitoringThresholds,
      serviceLevelIndicators: {
        rails_redis_client: {
          userImpacting: true,
          featureCategory: featureCategory,
          team: 'sre_observability',
          description: |||
            Aggregation of all Redis %s operations issued from the Rails codebase.

            %s
          ||| % [descriptiveName, additionalSLIText],
          significantLabels: ['type'],

          apdex: histogramApdex(
            histogram='gitlab_redis_client_requests_duration_seconds_bucket',
            selector={ storage: storage },
            satisfiedThreshold=0.5,
            toleratedThreshold=0.75,
          ),

          requestRate: rateMetric(
            counter='gitlab_redis_client_requests_total',
            selector={ storage: storage },
          ),

          errorRate: rateMetric(
            counter='gitlab_redis_client_exceptions_total',
            selector={ storage: storage },
          ),
        },

        primary_server: {
          userImpacting: true,
          featureCategory: featureCategory,
          team: 'sre_observability',
          description: |||
            Operations on the Redis primary for GitLab's %s Redis instance.
          ||| % descriptiveName,

          requestRate: rateMetric(
            counter='redis_commands_processed_total',
            selector='type="%s"' % redisName,
            instanceFilter='redis_instance_info{role="master"}'
          ),

          significantLabels: ['fqdn'],

          toolingLinks: [
            toolingLinks.kibana(title='Redis', index='redis', type=redisName),
            toolingLinks.kibana(title='Redis Slowlog', index='redis_slowlog', type=redisName),
          ],
        },

        secondary_servers: {
          userImpacting: true,  // userImpacting for data redundancy reasons
          featureCategory: featureCategory,
          team: 'sre_observability',
          description: |||
            Operations on the Redis secondaries for GitLab's %s Redis instance.
          ||| % descriptiveName,

          requestRate: rateMetric(
            counter='redis_commands_processed_total',
            selector='type="%s"' % redisName,
            instanceFilter='redis_instance_info{role="slave"}'
          ),

          significantLabels: ['fqdn'],
          serviceAggregation: false,
        },
      } + otherSlis,
    }),
}
