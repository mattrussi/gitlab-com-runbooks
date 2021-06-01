local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local utilizationMetric = metricsCatalog.utilizationMetric;

{
  pg_vacuum_time_per_day: utilizationMetric({
    title: 'Postgres Total Daily Vacuum Time',
    unit: 'seconds',
    appliesTo: ['patroni'],
    description: |||
      Measures the total time spent on vacuum operations per day.
    |||,
    resourceLabels: [],
    query: |||
      sum by (%(aggregationLabels)s) (
        increase(fluentd_pg_auto_vacuum_elapsed_seconds_total{%(selector)s}[1d])
      )
    |||,
  }),
}
