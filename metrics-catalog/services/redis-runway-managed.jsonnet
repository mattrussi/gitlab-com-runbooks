local redisArchetype = import 'service-archetypes/redis-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

local exemptedShards = [];

local trafficCessationAlertConfig = if std.length(exemptedShards) > 0 then
  {
    component_shard: {
      shard: {
        // By default all memorystore redis instances are monitored for alerts.
        // This allows us to exclude instances meant for testing.
        noneOf: exemptedShards,
      },
    },
  }
else
  true;

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
    tenants: ['runway'],
    monitoring: { shard: { enabled: true } },
    serviceLevelIndicators: {
      primary_server: {
        apdexSkip: 'apdex for redis is measured clientside',
        userImpacting: true,
        featureCategory: 'not_owned',
        serviceAggregation: false,
        shardLevelMonitoring: true,
        trafficCessationAlertConfig: trafficCessationAlertConfig,
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
  +
  {
    skippedMaturityCriteria: {
      'Structured logs available in Kibana': 'GCP-managed Memorystore Redis does not have kibana logs',
      'Service exists in the dependency graph': 'For now, no service is depending on this the redis service',
    },
  }
)
