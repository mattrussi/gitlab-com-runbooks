local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local config = import './gitlab-metrics-config.libsonnet';

local rdsMaxConnections = std.get(config.options, 'rdsMaxConnections', null);

{
  [if rdsMaxConnections != null then 'aws_rds_used_connections']: resourceSaturationPoint({
    title: 'AWS RDS Used Connections',
    severity: 's2',
    horizontallyScalable: false,
    appliesTo: ['rds'],
    grafana_dashboard_uid: 'rds_used_connections',
    description: |||
      The number of client network connections to the database instance.

      Instance Type: %s

      Further details: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html#rds-cw-metrics-instance
    |||,
    resourceLabels: [],
    query: |||
      aws_rds_database_connections_maximum
      /
      (%(rdsMaxConnections)d)
    |||,
    queryFormatConfig: {
      rdsMaxConnections: rdsMaxConnections
    },
    slos: {
      soft: 0.90,
      hard: 0.95,
      alertTriggerDuration: '5m',
    },
  }),
}
