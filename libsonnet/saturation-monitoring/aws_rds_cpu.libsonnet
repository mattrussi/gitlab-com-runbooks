local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;
local labelTaxonomy = import 'label-taxonomy/label-taxonomy.libsonnet';

{
  aws_rds_cpu_utilization: resourceSaturationPoint({
    title: 'CPU Utilization per RDS Instance',
    severity: 's2',
    horizontallyScalable: false,
    appliesTo: ['rds'],
    description: |||
      The percentage of CPU utilization.

      Additional details here: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html#rds-cw-metrics-instance
    |||,
    grafana_dashboard_uid: 'aws_rds_cpu_utilization',
    resourceLabels: [],
    linear_prediction_saturation_alert: '6h',  // Alert if this is going to exceed the hard threshold within 6h

    query: 'aws_rds_cpuutilization_maximum',
    slos: {
      soft: 0.90,
      hard: 0.95,
      alertTriggerDuration: '15m',
    },
  }),
}
