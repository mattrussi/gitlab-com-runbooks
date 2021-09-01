local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  pg_vacuum_activity: resourceSaturationPoint({
    title: 'Postgres Autovacuum Activity',
    severity: 's2',
    horizontallyScalable: true,  // We can add more vacuum workers, but at a resource utilization cost
    appliesTo: ['patroni', 'sentry'],
    description: |||
      Measures the number of active autovacuum workers, as a percentage of the maximum, configured
      via the `autovacuum_max_workers` setting.

      If this is saturated for a sustained period, it may indicate that postgres is struggling to keep
      up with vacuum activity.

      This could ultimately lead to a transaction ID wraparound situation: see
      https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/pg_xid_wraparound_alert.md
    |||,
    grafana_dashboard_uid: 'sat_pg_vacuum_activity',
    resourceLabels: [],
    query: |||
      (
        sum by (%(aggregationLabels)s) (
          avg_over_time(pg_stat_activity_autovacuum_active_workers_count{%(selector)s}[%(rangeInterval)s])
          and on (instance, job) (pg_replication_is_replica{%(selector)s} == 0)
        )
        or
        clamp_max(
          group by (%(aggregationLabels)s) (
            pg_settings_autovacuum_max_workers{%(selector)s}
            and on (instance, job) (pg_replication_is_replica{%(selector)s} == 0)
          ),
        0)
      )
      /
      avg by (%(aggregationLabels)s) (
        pg_settings_autovacuum_max_workers{%(selector)s}
        and on (instance, job) (pg_replication_is_replica{%(selector)s} == 0)
      )
    |||,
    slos: {
      soft: 0.90,
      hard: 1,
      alertTriggerDuration: '60m',
    },
  }),
}
