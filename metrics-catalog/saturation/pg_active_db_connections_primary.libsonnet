local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

local pgActiveDBConnectionsPrimary(database, grafanaSuffix='') =
  resourceSaturationPoint({
    title: 'Active Primary DB Connection Utilization',
    severity: 's3',
    horizontallyScalable: false,  // Connections to the primary are not horizontally scalable
    appliesTo: ['patroni'],
    description: |||
      Active db connection utilization on the primary node.

      Postgres is configured to use a maximum number of connections.
      When this resource is saturated, connections may queue.
    |||,
    grafana_dashboard_uid: 'sat_active_db_conns_primary' + grafanaSuffix,
    resourceLabels: ['fqdn'],
    query: |||
      sum without (state) (
        pg_stat_activity_count{datname="%(pgbouncerDatabase)s", state!="idle", %(selector)s} unless on(instance) (pg_replication_is_replica == 1)
      )
      / on (%(aggregationLabels)s)
      pg_settings_max_connections{%(selector)s}
    |||,
    queryFormatConfig: {
      pgbouncerDatabase: database,
    },
    slos: {
      soft: 0.70,
      hard: 0.80,
    },
  });

{
  pg_active_db_connections_primary: pgActiveDBConnectionsPrimary('gitlabhq_production'),
  registry_pg_active_db_connections_primary: pgActiveDBConnectionsPrimary('gitlabhq_registry', '_reg'),
}
