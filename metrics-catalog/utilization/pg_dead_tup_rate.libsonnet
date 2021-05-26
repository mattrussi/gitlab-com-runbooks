local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local utilizationMetric = metricsCatalog.utilizationMetric;

{
  pg_dead_tup_rate: utilizationMetric({
    title: 'Tracks the rate of dead tuple generation',
    unit: 'tuples',
    appliesTo: ['patroni', 'sentry'],
    description: |||
      Monitors the total rate at which dead tuples are being generated across all tables on the postgres instance.
    |||,
    resourceLabels: ['relname'],
    query: |||
      sum by (%(aggregationLabels)s) (
        deriv(pg_stat_user_tables_n_dead_tup{%(selector)s}[1h]) > 0
        and on (instance, job) (pg_replication_is_replica==0)
      )
    |||,
  }),
}
