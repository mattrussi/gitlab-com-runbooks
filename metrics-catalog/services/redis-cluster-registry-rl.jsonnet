local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local redisArchetype = import 'service-archetypes/redis-rails-archetype.libsonnet';
local redisHelpers = import './lib/redis-helpers.libsonnet';
local findServicesWithTag = (import 'servicemetrics/metrics-catalog.libsonnet').findServicesWithTag;

local registryRLBaseSelector = {
  type: 'RegistryRL',  // RL is shortened form of RateLimiting due to name length limits of GCP resources
};

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-cluster-registry-rl',  // name is shortened due to CloudDNS 255 char limits
    descriptiveName='Container Registry Ratelimiting in Redis Cluster',
    redisCluster=true
  )
  {
    // tenants: [ 'gitlab-gprd', 'gitlab-gstg', 'gitlab-pre' ],
    monitoringThresholds+: {
      apdexScore: 0.9995,
    },
    serviceLevelIndicators+: {
      registry_rl_redis_client: {
        userImpacting: false,
        severity: 's3',
        description: |||
          Redis Cluster for ratelimiting in Container Registry
        |||,

        apdex: histogramApdex(
          // This metric needs to come from Container registry app
          // histogram='<>',
          selector=registryRLBaseSelector,
          satisfiedThreshold=0.01,
          toleratedThreshold=0.1
        ),

        requestRate: rateMetric(
          // These metric needs to come from Container registry app
          // counter='<>',
          selector=registryRLBaseSelector,
        ),

        emittedBy: ['registry-rl'],

        significantLabels: ['instance', 'command'],
      },
    },
  }
  + redisHelpers.gitlabcomObservabilityToolingForRedis('redis-cluster-registry-rl')
)
