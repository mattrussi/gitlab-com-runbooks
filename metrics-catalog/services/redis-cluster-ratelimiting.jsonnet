local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-cluster-ratelimiting',
    // TODO: switch to `rate_limiting` after Rails app drops ClusterRateLimiting class
    // currently accepts both 'cluster_rate_limiting' and 'rate_limiting' during transition period
    railsStorageSelector={ storage: { oneOf: ['cluster_rate_limiting', 'rate_limiting'] } },
    descriptiveName='Redis Cluster Rate-Limiting'
  )
  {
    monitoringThresholds+: {
      apdexScore: 0.9995,
    },
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-cluster-ratelimiting')
)
