local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

local commonMemory = {
  severity: 's4',
  horizontallyScalable: true,
  appliesTo: metricsCatalog.findKubeProvisionedServices(first='web'),
  resourceLabels: ['pod', 'container'],
};
{
  kube_container_cpu: resourceSaturationPoint(commonMemory {
    title: 'Kube Container CPU Utilization',
    description: |||
      Kubernetes containers are allocated a share of CPU. Configured using resource requests.
      When this is exhausted, the container may be thottled.
    |||,
    grafana_dashboard_uid: 'sat_kube_container_cpu',
    burnRatePeriod: '1h',
    quantileAggregation: 0.99,
    capacityPlanning: { strategy: 'quantile99_1h' },
    alerting: { enabled: false },
    query: |||
      sum by (%(aggregationLabels)s) (
        rate(container_cpu_usage_seconds_total:labeled{container!="", container!="POD", %(selector)s}[%(rangeInterval)s])
      )
      /
      sum by(%(aggregationLabels)s) (
        kube_pod_container_resource_requests:labeled{container!="", container!="POD", resource="cpu", %(selector)s}
      )
    |||,
    slos: {
      soft: 0.95,
      hard: 0.99,
    },
  }),

  kube_container_cpu_limit: resourceSaturationPoint(commonMemory {
    title: 'Kube Container CPU over-utilization',
    description: |||
      Kubernetes containers can have a limit configured on how much CPU they can consume in
      a burst. If we are at this limit, exceeding the allocated requested resources, we
      should consider revisting the container's HPA configuration
    |||,
    grafana_dashboard_uid: 'sat_kube_container_cpu_limit',
    burnRatePeriod: '5m',
    capacityPlanning: { strategy: 'exclude' },
    query: |||
      sum by (%(aggregationLabels)s) (
        rate(container_cpu_usage_seconds_total:labeled{container!="", container!="POD", %(selector)s}[%(rangeInterval)s])
      )
      /
      sum by(%(aggregationLabels)s) (
        container_spec_cpu_quota:labeled{container!="", container!="POD", %(selector)s}
        /
        container_spec_cpu_period:labeled{container!="", container!="POD", %(selector)s}
      )
    |||,
    slos: {
      soft: 0.90,
      hard: 0.99,
      alertTriggerDuration: '15m',
    },
  }),
}
