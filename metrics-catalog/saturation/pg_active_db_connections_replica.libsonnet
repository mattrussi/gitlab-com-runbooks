local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

local pgActiveDBConnectionsReplica(database, grafanaSuffix='') =
  resourceSaturationPoint({
    title: 'Active Secondary DB Connection Utilization',
    severity: 's3',
    horizontallyScalable: true,  // Connections to the replicas are horizontally scalable
    appliesTo: ['patroni'],
    description: |||
      Active db connection utilization per replica node

      Postgres is configured to use a maximum number of connections.
      When this resource is saturated, connections may queue.
    |||,
    grafana_dashboard_uid: 'sat_active_db_conns_replica' + grafanaSuffix,
    resourceLabels: ['fqdn'],
    query: |||
      sum without (state) (
        pg_stat_activity_count{datname="%(pgbouncerDatabase)s", state!="idle", %(selector)s} and on(instance) (pg_replication_is_replica == 1)
      )
      / on (%(aggregationLabels)s)
      pg_settings_max_connections{%(selector)s}
    |||,
    queryFormatConfig: {
      pgbouncerDatabase: database,
    },
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  });

{
  pg_active_db_conn_replica: pgActiveDBConnectionsReplica('gitlabhq_production'),
  reg_pg_active_db_conn_replica: pgActiveDBConnectionsReplica('gitlabhq_registry', '_reg'),
}
