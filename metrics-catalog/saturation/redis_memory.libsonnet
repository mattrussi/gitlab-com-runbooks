local resourceSaturationPoint = (import 'servicemetrics/metrics.libsonnet').resourceSaturationPoint;
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

local commonDefition = {
  title: 'Redis Memory Utilization per Node',
  severity: 's2',
  horizontallyScalable: false,
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
};

{
  redis_memory: resourceSaturationPoint(commonDefition {
    appliesTo: std.filter(function(s) s != 'redis-tracechunks', metricsCatalog.findServicesWithTag(tag='redis')),  // All the redis except redis-tracechunks
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
    slos: {
      soft: 0.65,
      // Keep this low, since processes like the Redis RDB snapshot can put sort-term memory pressure
      // Ideally we don't want to go over 75%, so alerting at 70% gives us due warning before we hit
      //
      hard: 0.70,
    },
  }),

  redis_memory_tracechunks: resourceSaturationPoint(commonDefition {
    appliesTo: ['redis-tracechunks'],  // No need for tags, this is specifically targeted
    description: |||
      Redis memory utilization per node.

      As Redis memory saturates node memory, the likelyhood of OOM kills, possibly to the Redis process,
      become more likely.

      Trace chunks should be extremely transient (written to redis, then offloaded to objectstorage nearly immediately)
      so any uncontrolled growth in memory saturation implies a potentially significant problem.  Short term mitigation
      is usually to upsize the instances to have more memory while the underlying problem is identified, but low
      thresholds give us more time to investigate first

      This threshold is kept deliberately very low; because we use C2 instances we are generally overprovisioned
      for RAM, and because of the transient nature of the data here, it is advantageous to know early if there is any
      non-trivial storage occurring
    |||,
    grafana_dashboard_uid: 'sat_redis_memory_tracechunks',
    slos: {
      // Intentionally very low, maybe able to go lower.  See description above
      soft: 0.40,
      hard: 0.50,
    },
  }),
}
