local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-pubsub',
    // via Gitlab::Redis::Workhorse and Gitlab::Redis::Pubsub (initially, to be replaced by ActionCable)
    railsStorageSelector=redisHelpers.storageSelector({ oneOf: ['workhorse', 'pubsub', 'action_cable'] }),
    descriptiveName='Redis that handles predominantly pub/sub operations',
  )
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-pubsub')
)
