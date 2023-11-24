local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-db-load-balancing',
    railsStorageSelector={ storage: 'db_load_balancing' },
    descriptiveName='Redis DB load balancing'
  )
  {
    monitoringThresholds+: {
      apdexScore: 0.9995,
    },
  }
  // TODO: ensure that kubeConfig is setup with kube nodepool selectors
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-db-load-balancing')
  +
  {
    capacityPlanning: {
      components: [
        {
          name: 'disk_space',
          parameters: {
            ignore_outliers: [
              {
                start: '2023-05-31',  // https://gitlab.com/gitlab-com/gl-infra/capacity-planning/-/issues/1187#note_1532397578
                end: '2023-06-04',
              },
            ],
          },
        },
      ],
    },
  }
)
