local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  redis_secondary_cpu: resourceSaturationPoint({
    title: 'Redis Secondary CPU Utilization per Node',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: ['redis', 'redis-sidekiq', 'redis-cache', 'redis-tracechunks', 'redis-ratelimiting'],
    description: |||
      Redis Secondary CPU Utilization per Node.

      Redis is single-threaded. A single Redis server is only able to scale as far as a single CPU on a single host.
      CPU saturation on a secondary is not as serious as critical as saturation on a primary, but could lead to
      replication delays.
    |||,
    grafana_dashboard_uid: 'sat_redis_secondary_cpu',
    resourceLabels: ['fqdn'],
    burnRate: '5m',
    query: |||
      (
        rate(redis_cpu_user_seconds_total{%(selector)s}[%(rangeInterval)s])
        +
        rate(redis_cpu_sys_seconds_total{%(selector)s}[%(rangeInterval)s])
      )
      and on (instance) redis_instance_info{role!="master"}
    |||,
    slos: {
      soft: 0.85,
      hard: 0.95,
    },
  }),
}
