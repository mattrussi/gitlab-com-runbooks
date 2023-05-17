local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-cluster-chat-cache',
    railsStorageSelector={ storage: 'chat' },
    descriptiveName='Redis Cluster Chat Cache',
    redisCluster=true
  )
  {
    monitoringThresholds+: {
      apdexScore: 0.9995,
    },
    // disable alerts until we are receiving production traffic
    serviceLevelIndicators+: {
      // rails_cache SLI omitted as the application does not use any
      // ActiveSupport::Cache::RedisCacheStore for this service.
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
    },


  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-cluster-chat-cache')
)
