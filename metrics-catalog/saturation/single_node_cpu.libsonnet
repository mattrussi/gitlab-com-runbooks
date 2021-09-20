local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

{
  single_node_cpu: resourceSaturationPoint({
    title: 'Average CPU Utilization per Node',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findVMProvisionedServices(first='gitaly'),
    description: |||
      Average CPU utilization per Node.

      If average CPU is satured, it may indicate that a fleet is in need to horizontal or vertical scaling. It may also indicate
      imbalances in load in a fleet.
    |||,
    grafana_dashboard_uid: 'sat_single_node_cpu',
    resourceLabels: ['fqdn'],
    burnRatePeriod: '5m',
    // Note: we filter out nodes without `fqdn` labels because generally these are worker nodes
    // that we don't want to monitor with single_node_cpu
    query: |||
      avg without(cpu, mode) (1 - rate(node_cpu_seconds_total{fqdn!="", mode="idle", %(selector)s}[%(rangeInterval)s]))
    |||,
    slos: {
      soft: 0.90,
      hard: 0.95,
      alertTriggerDuration: '10m',
    },
  }),
}
