local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;
local labelTaxonomy = import 'label-taxonomy/label-taxonomy.libsonnet';

{
  aws_rds_disk_space: resourceSaturationPoint({
    title: 'Disk Space Utilization per RDS Instance',
    severity: 's2',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findServicesWithTag(tag='rds'),
    description: |||
      We are fully saturated when we are at 2GB remaining free space, we have
      no way of knowing the total available space and RDS will autoscale storage for us
      when we are at 10GB or 10% free space, whichever is greater.
    |||,
    grafana_dashboard_uid: 'sat_disk_space',
    resourceLabels: [labelTaxonomy.getLabelFor(labelTaxonomy.labels.node), 'device'],
    linear_prediction_saturation_alert: '6h',  // Alert if this is going to exceed the hard threshold within 6h

    query: |||
      (
        ( 2 * (1024*1024*1024))
        /
        (sum by (dbinstance_identifier) (aws_rds_free_storage_space_maximum)))
      )
    |||,
    slos: {
      soft: 0.90,
      hard: 0.95,
      alertTriggerDuration: '15m',
    },
  }),
}