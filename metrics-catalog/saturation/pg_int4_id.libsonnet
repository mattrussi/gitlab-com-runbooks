local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  pg_int4_id: resourceSaturationPoint({
    title: 'Postgres int4 ID capacity',
    severity: 's1',
    horizontallyScalable: false,
    appliesTo: ['patroni'],
    description: |||
      This measures used int4 primary key capacity in selected postgres tables. It is critically important that we do not reach
      saturation on this as GitLab will stop to work at this point.
    |||,
    grafana_dashboard_uid: 'sat_pg_int4_id',
    resourceLabels: ['table_name'],
    burnRatePeriod: '5m',
    query: |||
      max by (%(aggregationLabels)s) (
        pg_integer_capacity_current{%(selector)s}
        /
        pg_integer_capacity_maximum{%(selector)s}
      )
    |||,
    slos: {
      soft: 0.70,
      hard: 0.80,
    },
  }),
}
