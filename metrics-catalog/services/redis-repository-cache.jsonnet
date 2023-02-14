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
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-repository-cache')
)
