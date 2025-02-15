local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

{
  memorystore_redis_memory: resourceSaturationPoint({
    title: 'Memorystore Memory Utilization',
    severity: 's4',
    horizontallyScalable: false,
    appliesTo: metricsCatalog.findServicesWithTag(tag='runway-managed-redis'),
    description: |||
      Memorystore Redis memory utilization.

      See https://cloud.google.com/memorystore/docs/redis/monitor-instances#create-stackdriver-alert
    |||,
    grafana_dashboard_uid: 'sat_memorystore_redis_memory',
    resourceLabels: [],
    burnRatePeriod: '5m',
    staticLabels: {
      type: 'monitoring',
      tier: 'inf',
      stage: 'main',
    },
    query: |||
      max by (%(aggregationLabels)s) (
        stackdriver_redis_instance_redis_googleapis_com_stats_memory_usage_ratio{%(selector)s, role = "primary"}
      )
    |||,
    slos: {
      soft: 0.50,
      hard: 0.60,
    },
  }),
}
