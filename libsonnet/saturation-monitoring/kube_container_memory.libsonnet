local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

local servicesUsingRssSaturationMonitoring = std.set((import './kube_container_rss.libsonnet').kube_container_rss.appliesTo);

{
  kube_container_memory: resourceSaturationPoint({
    title: 'Kube Container Memory Utilization',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: std.filter(
      function(service)
        !std.member(servicesUsingRssSaturationMonitoring, service),
      metricsCatalog.findKubeProvisionedServices(first='web'),
    ),
    description: |||
      This uses the working set size from cAdvisor for the cgroup's memory usage. That may
      not be a good measure as it includes filesystem cache pages that are not necessarily
      attributable to the application inside the cgroup, and are permitted to be evicted
      instead of being OOM killed.
    |||,
    grafana_dashboard_uid: 'sat_kube_container_memory',
    resourceLabels: ['deployment'],
    useResourceLabelsAsMaxAggregationLabels: true,
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
    capacityPlanning: {
      saturation_dimension_dynamic_lookup_query: |||
        count by(deployment) (
          last_over_time(container_memory_working_set_bytes:labeled{deployment!="", %(selector)s}[1w:1d] @ end())
        )
      |||,
      saturation_dimension_dynamic_lookup_limit: 40,
    },
  }),
}
