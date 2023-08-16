local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local redisHelpers = import './lib/redis-helpers.libsonnet';

local railsCacheSelector = redisHelpers.storeSelector('RedisCacheStore');

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-cache',
    railsStorageSelector=redisHelpers.storageSelector('cache'),
    descriptiveName='Redis Cache'
  )
  {
    monitoringThresholds+: {
      apdexScore: 0.9995,
    },
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-cache')
  +
  {
    capacityPlanning: {
      components: [
        {
          name: 'redis_primary_cpu',
          parameters: {
            changepoints: [
              '2023-02-01',  // repository-cache split
            ],
          },
        },
        {
          name: 'disk_space',
          parameters: {
            ignore_outliers: [
              {
                start: '2023-03-01',
                end: '2023-03-15',
              },
              {
                start: '2023-05-09',  // https://gitlab.com/gitlab-com/gl-infra/production/-/issues/13813
                end: '2023-05-22',  // https://gitlab.com/gitlab-com/gl-infra/production/-/issues/14497
              },
            ],
          },
        },
      ],
    },
  }
)
