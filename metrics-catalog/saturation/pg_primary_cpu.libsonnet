local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  pg_primary_cpu: resourceSaturationPoint({
    title: 'Average CPU Utilization on Postgres Primary Instance',
    severity: 's2',
    horizontallyScalable: false,

    // Unfortunately this saturation metric relies on node_exporter data from prometheus-default shards,
    // and postgres_exporter data from the prometheus-db shards, so we need to evaluate it in Thanos
    // which is not ideal.
    dangerouslyThanosEvaluated: true,

    appliesTo: ['patroni'],
    description: |||
      Average CPU utilization across all cores on the Postgres primary instance.
    |||,
    grafana_dashboard_uid: 'sat_pg_primary_cpu',
    resourceLabels: ['fqdn'],
    burnRatePeriod: '5m',
    query: |||
      avg without(cpu, mode) (
        1
        -
        (
          rate(node_cpu_seconds_total{mode="idle", %(selector)s}[%(rangeInterval)s])
          and on(fqdn)
          pg_replication_is_replica{%(selector)s} == 0
        )
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),
}
