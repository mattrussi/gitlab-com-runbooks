local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics.libsonnet';
local utilizationMetric = metricsCatalog.utilizationMetric;

{
  pg_vacuum_time_per_day: utilizationMetric({
    title: 'Postgres Total Daily Vacuum Time',
    unit: 'seconds',
    appliesTo: ['patroni'],
    description: |||
      Measures the total time spent on vacuum operations per day.
    |||,
    rangeDuration: '1d',
    resourceLabels: [],
    query: |||
      sum by (%(aggregationLabels)s) (
        increase(fluentd_pg_auto_vacuum_elapsed_seconds_total{%(selector)s}[%(rangeDuration)s])
      )
    |||,
  }),
}
