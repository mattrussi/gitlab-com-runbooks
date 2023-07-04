local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local redisHelpers = import './lib/redis-helpers.libsonnet';

local railsCacheSelector = { store: 'FeatureFlagStore' };

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-cluster-feature-flag',
    railsStorageSelector={ storage: 'feature_flag' },
    descriptiveName='Redis Cluster Feature Flag',
    redisCluster=true
  )
  {
    monitoringThresholds+: {
      apdexScore: 0.9995,
    },
    serviceLevelIndicators+: {
      // Rails Cache uses metrics from the main application to guage to performance of the Redis cache
      // This is useful since it's not easy for us to directly calculate an apdex from the Redis metrics
      // directly
      rails_cache: {
        userImpacting: true,
        featureCategory: 'not_owned',
        description: |||
          Rails ActiveSupport Cache operations against the Feature Flag instance
        |||,

        apdex: histogramApdex(
          histogram='gitlab_cache_operation_duration_seconds_bucket',
          selector=railsCacheSelector,
          satisfiedThreshold=0.1,
          toleratedThreshold=0.25
        ),

        requestRate: rateMetric(
          counter='gitlab_cache_operation_duration_seconds_count',
          selector=railsCacheSelector,
        ),

        significantLabels: [],
      },
    },
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-cluster-feature-flag')
)
