local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-sidekiq-catchall-a',
    // this should match the `queues_shard_xxx` pattern in
    // https://gitlab.com/gitlab-org/gitlab/-/blob/f4595d2f5d32911ec4aab4ee0d11821873c0e3c5/lib/gitlab/redis/queues.rb#L64
    railsStorageSelector=redisHelpers.storageSelector('queues_shard_catchall_a'),
    descriptiveName='Redis Sidekiq Catchall shard A'
  )
  {
    serviceLevelIndicators+: {
      primary_server+: {
        userImpacting: true,
        severity: 's4',
      },
      secondary_servers+: {
        userImpacting: true,
        severity: 's4',
      },
      rails_redis_client+: {
        userImpacting: true,
        severity: 's4',
        description: |||
          Aggregation of all Redis operations issued to the Redis Sidekiq service from the Rails codebase.

          If this SLI is experiencing a degradation, it may be caused by saturation in the Redis Sidekiq instance caused by
          high traffic volumes from Sidekiq clients (Rails or other sidekiq jobs), or very large messages being delivered
          via Sidekiq.

          Reviewing Sidekiq job logs may help the investigation.
        |||,
      },
    },
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-sidekiq-catchall-a')
)
