local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local redisHelpers = import './lib/redis-helpers.libsonnet';

local railsCacheSelector = redisHelpers.storeSelector('RedisCacheStore');

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-cluster-shared-state',
    railsStorageSelector=redisHelpers.storageSelector('cluster_shared_state'),
    descriptiveName='Redis SharedState in Redis Cluster',
    redisCluster=true
  )
  {
    // TODO: set severity to s2 after migration is completed
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
  } + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-cluster-shared-state')
)
