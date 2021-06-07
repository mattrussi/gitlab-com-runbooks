local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local kubeSaturationHelpers = import 'helpers/kube_saturation_helpers.libsonnet';

{
  pg_primary_cpu: resourceSaturationPoint({
    title: 'Average CPU Utilization on Postgres Primary Instance',
    severity: 's2',
    horizontallyScalable: false,
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
