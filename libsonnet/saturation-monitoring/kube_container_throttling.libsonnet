local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;
local labelTaxonomy = import 'label-taxonomy/label-taxonomy.libsonnet';

{
  single_node_cpu: resourceSaturationPoint({
    title: 'Kube container throttling',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findKubeProvisionedServices(first='web'),
    description: |||
      Kube container throttling

      A container will be throttled if it reaches the configured cpu limit for the
      horizontal pod autoscaler. Or when other containers on the node are overutilizing
      the the CPU.

      To get around this, consider increasing the limit for this workload.
    |||,
    grafana_dashboard_uid: 'sat_single_node_cpu',
    burnRatePeriod: '5m',
    query: |||
      avg without(cpu, mode) (1 - rate(node_cpu_seconds_total{mode="idle", %(selector)s}[%(rangeInterval)s]))
    |||,
    slos: {
      soft: 0.90,
      hard: 0.95,
      alertTriggerDuration: '10m',
    },
  }),
}
