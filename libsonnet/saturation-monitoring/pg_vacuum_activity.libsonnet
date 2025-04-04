local resourceSaturationPoint = (import 'servicemetrics/metrics.libsonnet').resourceSaturationPoint;
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

{
  pg_vacuum_activity: resourceSaturationPoint({
    title: 'Postgres Autovacuum Activity',
    severity: 's2',
    horizontallyScalable: true,  // We can add more vacuum workers, but at a resource utilization cost

    // Use patroni tag, not postgres since we only want clusters that have primaries
    // not postgres-archive, or postgres-delayed nodes for example
    appliesTo: metricsCatalog.findServicesWithTag(tag='postgres_with_primaries'),

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
    capacityPlanningStrategy: 'quantile95_1w',  // Use a p95 value over a 1 week period for capacity planning
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
