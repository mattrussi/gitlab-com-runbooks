local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-cluster-queues-meta',
    railsStorageSelector=redisHelpers.storageSelector('queues_metadata'),
    descriptiveName='Redis Cluster Queues Metadata',
    redisCluster=true
  )
  {
    tenants: [ 'gitlab-gprd', 'gitlab-gstg', 'gitlab-pre' ],
    // disable alerts until we are receiving production traffic
    serviceLevelIndicators+: {
      rails_redis_client+: {
        userImpacting: true,
        severity: 's4',
      },
      primary_server+: {
        userImpacting: true,
        severity: 's4',
      },
      secondary_servers+: {
        userImpacting: true,
        severity: 's4',
      },
    },
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-cluster-queues-meta')
)
