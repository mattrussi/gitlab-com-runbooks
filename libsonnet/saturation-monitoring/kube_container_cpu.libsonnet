local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

local commonDefinition = {
  title: 'Kube Container CPU Utilization',
  severity: 's4',
  horizontallyScalable: true,
  appliesTo: metricsCatalog.findKubeProvisionedServices(first='web', excluding=['sidekiq']),
  description: |||
    Kubernetes containers are allocated a share of CPU. When this is exhausted, the container may be thottled.
  |||,
  grafana_dashboard_uid: 'sat_kube_container_cpu',
  resourceLabels: ['pod', 'container'],
  burnRatePeriod: '5m',
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
};

local sidekiqDefinition = commonDefinition {
  appliesTo: ['sidekiq'],
  grafana_dashboard_uid: 'sat_sidekiq_kube_container_cpu',
  capacityPlanning: {
    strategy: 'exclude',
  },
};

{
  kube_container_cpu: resourceSaturationPoint(commonDefinition),
  sidekiq_kube_container_cpu: resourceSaturationPoint(sidekiqDefinition),
}
