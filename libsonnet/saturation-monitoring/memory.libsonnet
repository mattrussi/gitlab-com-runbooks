local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;
local labelTaxonomy = import 'label-taxonomy/label-taxonomy.libsonnet';

{
  memory: resourceSaturationPoint({
    title: 'Memory Utilization per Node',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findVMProvisionedServices(first='gitaly'),
    description: |||
      Memory utilization per device per node.
    |||,
    grafana_dashboard_uid: 'sat_memory',
    resourceLabels: [labelTaxonomy.getLabelFor(labelTaxonomy.labels.node)],
    // Filter out fqdn nodes as these could be CI runners
    query: |||
      instance:node_memory_utilization:ratio{%(selector)s} or instance:node_memory_utilisation:ratio{%(selector)s}
    |||,
    slos: {
      soft: 0.90,
      hard: 0.98,
    },
  }),
}
