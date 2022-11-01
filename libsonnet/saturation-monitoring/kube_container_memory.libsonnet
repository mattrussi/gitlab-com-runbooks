local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

{
  kube_container_memory: resourceSaturationPoint({
    title: 'Kube Container Memory Utilization',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findKubeProvisionedServices(first='web'),
    description: |||
      This uses the working set size from cAdvisor for the cgroup's memory usage. That may
      not be a good measure as it includes filesystem cache pages that are not necessarily
      attributable to the application inside the cgroup, and are permitted to be evicted
      instead of being OOM killed.
    |||,
    grafana_dashboard_uid: 'sat_kube_container_memory',
    resourceLabels: [],
    // burnRatePeriod: '5m',
    query: |||
      container_memory_working_set_bytes:labeled{container!="", container!="POD", %(selector)s}
      /
      (container_spec_memory_limit_bytes:labeled{container!="", container!="POD", %(selector)s} > 0)
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
      alertTriggerDuration: '15m',
    },
  }),
}
