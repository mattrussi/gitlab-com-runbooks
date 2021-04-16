local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  redis_memory: resourceSaturationPoint({
    title: 'Redis Memory Utilization per Node',
    severity: 's2',
    horizontallyScalable: false,
    appliesTo: ['redis', 'redis-sidekiq', 'redis-cache'],
    description: |||
      Redis memory utilization per node.

      As Redis memory saturates node memory, the likelyhood of OOM kills, possibly to the Redis process,
      become more likely.

      For caches, consider lowering the `maxmemory` setting in Redis. For non-caching Redis instances,
      this has been caused in the past by credential stuffing, leading to large numbers of web sessions.

      This threshold is kept deliberately low, since Redis RDB snapshots could consume a significant amount of memory,
      especially when the rate of change in Redis is high, leading to copy-on-write consuming more memory than when the
      rate-of-change is low.
    |||,
    grafana_dashboard_uid: 'sat_redis_memory',
    resourceLabels: ['fqdn'],
    query: |||
      max by (%(aggregationLabels)s) (
        label_replace(redis_memory_used_rss_bytes{%(selector)s}, "memtype", "rss","","")
        or
        label_replace(redis_memory_used_bytes{%(selector)s}, "memtype", "used","","")
      )
      /
      avg by (%(aggregationLabels)s) (
        node_memory_MemTotal_bytes{%(selector)s}
      )
    |||,
    slos: {
      soft: 0.65,
      // Keep this low, since processes like the Redis RDB snapshot can put sort-term memory pressure
      // Ideally we don't want to go over 75%, so alerting at 70% gives us due warning before we hit
      //
      hard: 0.70,
    },
  }),
}
