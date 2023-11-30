local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;
local labelTaxonomy = import 'label-taxonomy/label-taxonomy.libsonnet';

{
  aws_rds_freeable_memory: resourceSaturationPoint({
    title: 'Freeable Memory for an RDS instance',
    severity: 's4',
    horizontallyScalable: false,
    appliesTo: ['rds'],
    description: |||
      The amount of available random access memory. This metric reports the value of the MemAvailable field of /proc/meminfo.

      A high saturation point indicates that Swap may be in use lowering the performance of an RDS instance.

      Since we do not know the memory allocation of an RDS instance, we begin alerting when we are below 1GB of freeable memory.

      Additional details here: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html#rds-cw-metrics-instance
    |||,
    grafana_dashboard_uid: 'aws_rds_freeable_memory',
    resourceLabels: [],
    linear_prediction_saturation_alert: '6h',  // Alert if this is going to exceed the hard threshold within 6h

    query: |||
      (
        ( 1 * (1024*1024*1024))
        /
        (sum by (dbinstance_identifier) (aws_rds_freeable_memory_maximum))
      )
    |||,
    slos: {
      soft: 0.95,
      hard: 0.99,
      alertTriggerDuration: '30m',
    },
  }),

  aws_rds_swap_usage: resourceSaturationPoint({
    title: 'Swap usage for an RDS instance',
    severity: 's2',
    horizontallyScalable: false,
    appliesTo: ['rds'],
    description: |||
      The amount of used swap.

      A high saturation point indicates that Swap may be in use lowering the performance of an RDS instance.

      Since we do not know the memory allocation of an RDS instance, we begin alerting when we are using 1GB of swap.
      Swap is usually used a little even when an instance isn't under pressure, therefore we do not alert when we are using
      a value greater than 0.  Otherwise we'd always be alerting.

      Additional details here: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html#rds-cw-metrics-instance
    |||,
    grafana_dashboard_uid: 'aws_rds_swap_usage',
    resourceLabels: [],

    query: |||
      (
        (sum by (dbinstance_identifier) (aws_rds_swap_usage))
        /
        ( 1 * (1024*1024*1024))
      )
    |||,
    slos: {
      soft: 0.05,
      hard: 0.1,
      alertTriggerDuration: '15m',
    },
  }),
}
