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
  {
    tenants: [ 'gitlab-gprd', 'gitlab-gstg', 'gitlab-pre' ],
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis')
  + {
    capacityPlanning: {
      components: [
        {
          name: 'kube_container_memory',
          parameters: {
            ignore_outliers: [
              {
                // https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17753
                start: '2024-03-08',
                end: '2024-03-25',
              },
            ],
          },
        },
        {
          name: 'kube_go_memory',
          parameters: {
            ignore_outliers: [
              {
                // https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17753
                start: '2024-03-08',
                end: '2024-03-25',
              },
            ],
          },
        },
      ],
    },
  }
)
