local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local redisHelpers = import './lib/redis-helpers.libsonnet';

local railsCacheSelector = redisHelpers.storeSelector('RedisCacheStore');

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-cluster-shared-state',
    railsStorageSelector=redisHelpers.storageSelector({ oneOf: ['cluster_shared_state', 'shared_state'] }),
    descriptiveName='Redis SharedState in Redis Cluster',
    redisCluster=true
  )
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-cluster-shared-state')
)
