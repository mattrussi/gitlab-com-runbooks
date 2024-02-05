local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local config = import './gitlab-metrics-config.libsonnet';

local rdsMonitoring = std.get(config.options, 'rdsMonitoring', false);
local rdsInstanceRAMBytes = std.get(config.options, 'rdsInstanceRAMBytes', null);

{
  [if rdsMonitoring && rdsInstanceRAMBytes != null then 'aws_rds_used_connections']: resourceSaturationPoint({
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

    // RDS Leverages a special function for determining the maximm allowed
    // connections: `LEAST({DBInstanceClassMemory/9531392}, 5000)`
    // Reference: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html
    // We leverage this as part of our query below.

    // Note that we are using a metric, `rds_max_connections` to capture the capacity of
    // connections allotted by an RDS instance.  This is to be defined by the
    // customer as a prometheus recording rule.  Note that the label `dbinstance_identifier` is
    // required for this query to operate appropriately.
    query: |||
      sum by (dbinstance_identifier) (aws_rds_database_connections_maximum)
      /
      clamp_min((%(rdsInstanceRAMBytes)s)/9531392, 5000)
    |||,
    queryFormatConfig: {
      // Note that this value can be an integer bytes value, or a
      // PromQL expression, such as a recording rule
      rdsInstanceRAMBytes: rdsInstanceRAMBytes,
    },
    slos: {
      soft: 0.90,
      hard: 0.95,
      alertTriggerDuration: '5m',
    },
  }),
}
