local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-cluster-ratelimiting',
    // TODO: switch to `rate_limiting` after Rails app drops ClusterRateLimiting class
    railsStorageSelector={ storage: 'cluster_rate_limiting' },
    descriptiveName='Redis Cluster Rate-Limiting',
    redisCluster=true
  )
  {
    monitoringThresholds+: {
      apdexScore: 0.9995,
    },
    // disable alerts until we are receiving production traffic
    serviceLevelIndicators+: {
      rails_redis_client+: {
        userImpacting: false,
        severity: 's4',
      },
      primary_server+: {
        userImpacting: false,
        severity: 's4',
      },
      secondary_servers+: {
        userImpacting: false,
        severity: 's4',
      },
      cluster_servers+: {
        userImpacting: false,
        severity: 's4',
      },
    },
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-cluster-ratelimiting')
)
