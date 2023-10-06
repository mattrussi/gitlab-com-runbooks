local redisHelpers = import './lib/redis-helpers.libsonnet';
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-repository-cache',
    railsStorageSelector=redisHelpers.storageSelector('repository_cache'),
    descriptiveName='Redis Repository Cache'
  )
  {
    monitoringThresholds+: {
      apdexScore: 0.9995,
    },
    serviceLevelIndicators+: {
      rails_cache: {
        userImpacting: true,
        featureCategory: 'not_owned',
        description: |||
          Rails ActiveSupport Cache operations against the Redis Repository Cache
        |||,

        apdex: histogramApdex(
          histogram='gitlab_cache_operation_duration_seconds_bucket',
          selector=redisHelpers.storeSelector('RedisRepositoryCache'),
          satisfiedThreshold=0.01,
          toleratedThreshold=0.1
        ),

        requestRate: rateMetric(
          counter='gitlab_cache_operation_duration_seconds_count',
          selector=redisHelpers.storeSelector('RedisRepositoryCache'),
        ),

        significantLabels: [],
      },
    },
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-repository-cache')
  + {
    capacityPlanning+: {
      components: [
        {
          name: 'disk_space',
          parameters: {
            ignore_outliers: [
              {
                end: '2023-02-20',
                start: '2023-01-01',
              },
              {
                end: '2023-06-04',
                start: '2023-06-01',
              },
            ],
          },
        },
      ],
    },
  },
)
