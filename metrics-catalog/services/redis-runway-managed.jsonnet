local redisArchetype = import 'service-archetypes/redis-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-runway-managed',
    descriptiveName='Redis managed by Runway'
  )
  {
    tags: [
      // Do not include 'redis' tag for now since we are directly using stackdriver metrics.
      // See https://gitlab.com/gitlab-com/gl-infra/platform/runway/team/-/issues/406
      // Note that because this is a managed redis, we do not have finer grain node stats.
      'runway-managed-redis',
    ],
    provisioning: { runway: false, vms: false, kubernetes: false },
    tenants: ['gitlab-gprd', 'gitlab-gstg'],
    monitoring: { shard: { enabled: true } },
    serviceLevelIndicators: {
      primary_server: {
        apdexSkip: 'apdex for redis is measured clientside',
        userImpacting: true,
        featureCategory: 'not_owned',
        serviceAggregation: false,
        description: |||
          Operations on the Redis primary for Runway managed memorystore instances.
        |||,
        requestRate: metricsCatalog.gaugeMetric(
          gauge='stackdriver_redis_instance_redis_googleapis_com_commands_calls',
          selector={ type: 'redis-runway-managed' },
          samplingInterval=60,  //seconds. See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-redis
        ),

        significantLabels: ['instance'],

        toolingLinks: [],
      },
    },
  }
)
