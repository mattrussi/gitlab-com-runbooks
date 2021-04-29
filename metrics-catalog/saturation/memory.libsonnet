local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local kubeSaturationHelpers = import 'helpers/kube_saturation_helpers.libsonnet';

{
  memory: resourceSaturationPoint({
    title: 'Memory Utilization per Node',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: { allExcept: ['nat', 'waf', 'monitoring'] + kubeSaturationHelpers.kubeOnlyServices },
    description: |||
      Memory utilization per device per node.
    |||,
    grafana_dashboard_uid: 'sat_memory',
    resourceLabels: ['fqdn'],
    query: |||
      instance:node_memory_utilization:ratio{%(selector)s}
    |||,
    slos: {
      soft: 0.90,
      hard: 0.98,
    },
  }),
}
