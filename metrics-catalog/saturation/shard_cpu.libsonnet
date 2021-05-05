local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local kubeSaturationHelpers = import 'helpers/kube_saturation_helpers.libsonnet';

{
  shard_cpu: resourceSaturationPoint({
    title: 'Average CPU Utilization per Shard',
    severity: 's3',
    horizontallyScalable: true,
    appliesTo: { allExcept: ['nat', 'waf', 'console-node', 'deploy-node', 'security' /* ops-only security scanning service */] + kubeSaturationHelpers.kubeOnlyServices, default: 'sidekiq' },
    description: |||
      This resource measures average CPU utilization across an all cores in a shard of a
      service fleet. If it is becoming saturated, it may indicate that the
      shard needs horizontal or vertical scaling.
    |||,
    grafana_dashboard_uid: 'sat_shard_cpu',
    resourceLabels: ['shard'],
    burnRatePeriod: '5m',
    query: |||
      1 - avg by (%(aggregationLabels)s) (
        rate(node_cpu_seconds_total{mode="idle", %(selector)s}[%(rangeInterval)s])
      )
    |||,
    slos: {
      soft: 0.85,
      hard: 0.95,
    },
  }),
}
