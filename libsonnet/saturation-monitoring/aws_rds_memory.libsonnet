local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;
local labelTaxonomy = import 'label-taxonomy/label-taxonomy.libsonnet';
local config = import './gitlab-metrics-config.libsonnet';

local rdsMonitoring = std.get(config.options, 'rdsMonitoring', false);
local rdsInstanceRAMGB = std.get(config.options, 'rdsInstanceRAMGB', null);

{
  [if rdsMonitoring && rdsInstanceRAMGB != null then 'aws_rds_freeable_memory']: resourceSaturationPoint({
    title: 'Freeable Memory for an RDS instance',
    severity: 's4',
    horizontallyScalable: false,
    appliesTo: ['rds'],
    description: |||
      The amount of available freeable random access memory. This metric reports the value of the MemAvailable field of /proc/meminfo.

      A high saturation point indicates that Swap may be in use, lowering the performance of an RDS instance.

      Additional details here: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html#rds-cw-metrics-instance
    |||,
    grafana_dashboard_uid: 'aws_rds_freeable_memory',
    resourceLabels: [],
    linear_prediction_saturation_alert: '6h',  // Alert if this is going to exceed the hard threshold within 6h

    query: |||
      1- (sum by (dbinstance_identifier) (aws_rds_freeable_memory_maximum)
      /
      (%(rdsInstanceRAMGB)d * 1024 * 1024 * 1024))
    |||,
    queryFormatConfig: {
      rdsInstanceRAMGB: rdsInstanceRAMGB
    },
    slos: {
      soft: 0.95,
      hard: 0.99,
      alertTriggerDuration: '30m',
    },
  }),
}
