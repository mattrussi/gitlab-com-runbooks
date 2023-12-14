local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis',
    railsStorageSelector=redisHelpers.storageSelector({ oneOf: ['shared_state', 'buffered_counter'] }),
    descriptiveName='Persistent Redis',
  )
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis')
)
