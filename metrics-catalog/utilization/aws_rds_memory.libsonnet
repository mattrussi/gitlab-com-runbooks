local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local utilizationMetric = metricsCatalog.utilizationMetric;
local config = import './gitlab-metrics-config.libsonnet';

{
  aws_rds_swap_usage: utilizationMetric({
    title: 'Swap usage for an RDS instance',
    unit: 'bytes',
    appliesTo: ['rds'],
    description: |||
      The amount of used swap.  While some swap use may be expected, high
      usage may be an indicator of poor performance of the RDS instance.

      Additional details here: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-metrics.html#rds-cw-metrics-instance
    |||,
    resourceLabels: [],

    query: '(sum by (dbinstance_identifier) (aws_rds_swap_usage_maximum))',
  }),
}
