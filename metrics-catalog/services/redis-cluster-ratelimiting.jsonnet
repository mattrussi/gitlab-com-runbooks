local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-cluster-ratelimiting',
    railsStorageSelector=redisHelpers.excludeOpsGitlabNet { storage: 'rate_limiting' },
    descriptiveName='Redis Cluster Rate-Limiting',
    redisCluster=true
  )
  {
    monitoringThresholds+: {
      apdexScore: 0.9995,
    },
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-cluster-ratelimiting')
)
