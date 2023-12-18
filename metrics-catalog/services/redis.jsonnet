local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis',
    // only Gitlab::Redis::BufferedCounter use ~service::Redis
    // this will be removed when buffered counter workload is migrated to redis-cluster-shared-state
    railsStorageSelector=redisHelpers.storageSelector('buffered_counter'),
    descriptiveName='Persistent Redis',
  )
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis')
)
