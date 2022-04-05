local resourceSaturationPoint = (import 'servicemetrics/metrics.libsonnet').resourceSaturationPoint;
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

{
  pg_vacuum_activity: resourceSaturationPoint({
    title: 'Postgres Autovacuum Activity (sampled)',
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

  pg_vacuum_activity_v2: resourceSaturationPoint({
    title: 'Postgres Autovacuum Activity (non-sampled)',
    severity: 's2',
    horizontallyScalable: true,  // We can add more vacuum workers, but at a resource utilization cost

    // Use patroni tag, not postgres since we only want clusters that have primaries
    // not postgres-archive, or postgres-delayed nodes for example
    appliesTo: metricsCatalog.findServicesWithTag(tag='postgres_fluent_csvlog_monitoring'),

    description: |||
      This measures the total amount of time spent each day by autovacuum workers, as a percentage of total autovacuum capacity.

      This resource uses the `auto_vacuum_elapsed_seconds` value logged by the autovacuum worker, and aggregates this across all
      autovacuum jobs. In the case that there are 10 autovacuum workers, the total capacity is 10-days worth of autovacuum time per day.

      Once the system is performing 10 days worth of autovacuum per day, the capacity will be saturated.

      This resource is primarily intended to be used for long-term capacity planning.
    |||,
    grafana_dashboard_uid: 'sat_pg_vacuum_activity_v2',
    resourceLabels: [],
    burnRatePeriod: '1d',
    query: |||
      sum by (%(aggregationLabels)s) (
        rate(fluentd_pg_auto_vacuum_elapsed_seconds_total{env="gprd"}[1d])
        and on (fqdn) (pg_replication_is_replica{%(selector)s} == 0)
      )
      /
      avg by (%(aggregationLabels)s) (
        pg_settings_autovacuum_max_workers{%(selector)s}
        and on (instance, job) (pg_replication_is_replica{%(selector)s} == 0)
      )
    |||,
    slos: {
      soft: 0.70,
      hard: 0.90,
    },
  }),

}
