local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-repository-cache',
    railsStorageSelector={ storage: 'repository_cache' },
    descriptiveName='Redis Repository Cache'
  )
  {
    monitoringThresholds+: {
      apdexScore: 0.9995,
    },
    serviceLevelIndicators+: {
      rails_redis_client+: {
        userImpacting: false,
        severity: 's4',
        team: 'scalability-857-redis-functional-partitioning',
      },
      primary_server+: {
        userImpacting: false,
        severity: 's4',
        team: 'scalability-857-redis-functional-partitioning',
      },
      secondary_servers+: {
        userImpacting: false,
        severity: 's4',
        team: 'scalability-857-redis-functional-partitioning',
      },
    },

  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-repository-cache')
)
