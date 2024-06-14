local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

{
  // Similar to kube_pool_cpu, but for all nodegroups and not tied to specific services
  // so as to include mixed-workload nodegroups such as are found in GET CNH deployments
  node_group_cpu: resourceSaturationPoint({
    title: 'Average Node Pool CPU Utilization',
    severity: 's3',
    horizontallyScalable: true,  // Technically true, but in practice it more likely to scale node *types* in GET deploys
    appliesTo: ['kube'],
    description: |||
      This resource measures average CPU utilization across an all cores in a node group

      If it is becoming saturated, it may indicate that the node group needs resizing.
    |||,
    grafana_dashboard_uid: 'sat_kube_pool_cpu',
    resourceLabels: [],
    burnRatePeriod: '5m',
    query: |||
      1 - avg by (%(aggregationLabels)s) (
        rate(node_cpu_seconds_total{mode="idle", type=~".*pool"}[%(rangeInterval)s])
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),
}
