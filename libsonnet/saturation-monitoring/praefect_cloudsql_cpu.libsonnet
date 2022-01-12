local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  praefect_cloudsql_cpu: resourceSaturationPoint({
    title: 'Average CPU Utilization',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: ['monitoring'],
    description: |||
      Average CPU utilization.

      See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
      more details
    |||,
    grafana_dashboard_uid: 'sat_praefect_cloudsql_cpu',
    resourceLabels: ['database_id'],
    burnRatePeriod: '5m',
    staticLabels: {
      type: 'praefect',
      tier: 'stor',
      stage: 'main',
    },
    query: |||
      avg_over_time(stackdriver_cloudsql_database_cloudsql_googleapis_com_database_cpu_utilization{database_id=~".+:praefect-db.+", %(selector)s}[%(rangeInterval)s])
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),
}
