local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;
local labelTaxonomy = import 'label-taxonomy/label-taxonomy.libsonnet';
local config = import './gitlab-metrics-config.libsonnet';

// input for this is in GB, we'll convert it to bytes below
local rdsMaxAllocatedStorage = std.get(config.options, 'rdsMaxAllocatedStorage', null);

{
    [if rdsMaxAllocatedStorage != null then 'aws_rds_disk_space']: resourceSaturationPoint({
    title: 'Disk Space Utilization per RDS Instance',
    severity: 's2',
    horizontallyScalable: true,
    appliesTo: ['rds'],
    description: |||
      Disk space used by the database

      We use the disk space reported by all relations from `pg_database_size` and use this as a saturation point against the
      maximum size that RDS is configured too.  This may not be the size of the active disk as RDS autoscales storage for us.

      Additional details here: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html#rds-cw-metrics-instance
    |||,
    grafana_dashboard_uid: 'aws_rds_disk_space',
    resourceLabels: [],
    linear_prediction_saturation_alert: '6h',  // Alert if this is going to exceed the hard threshold within 6h

    // Sum ALL relations stored on the RDS instance
    query: |||
      sum(pg_database_size_bytes)
      /
      (%(rdsMaxAllocatedStorage)d * (1024 * 1024 * 1024))
    |||,
    queryFormatConfig: {
      rdsMaxAllocatedStorage: rdsMaxAllocatedStorage
    },
    slos: {
      soft: 0.95,
      hard: 0.99,
      alertTriggerDuration: '30m',
    },
  }),
}
