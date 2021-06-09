local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local saturationHelpers = import 'helpers/saturation_helpers.libsonnet';

{
  kube_container_cpu: resourceSaturationPoint({
    title: 'Kube Container CPU Utilization',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: saturationHelpers.kubeProvisionedServices,
    description: |||
      Kubernetes containers can have a limit on allocated shares of CPU. In this case the container
      may be throttled if the limit is exhausted. This is in contrast to unlimited containers, where
      usage above the requested shares is allowed if the node still has unused resources. Unlimited
      containers are not accounted for in this saturation metric.
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
  }),
}

{
  kube_container_cpu_shares: resourceSaturationPoint({
    title: 'Kube Container CPU Utilization of Requested Shares',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: saturationHelpers.kubeProvisionedServices,
    description: |||
      Kubernetes containers are allocated a share of CPU (called "CPU requests" in K8s). When this is exhausted,
      the container may be throttled if the node doesn't have additional allocatable capacity. This is in
      contrast to container CPU quota (called "limits" in K8s), which prevent to use available capacity beyond
      the limit.
    |||,
    grafana_dashboard_uid: 'sat_kube_container_cpu_shares',
    resourceLabels: ['pod', 'container'],
    burnRatePeriod: '5m',
    query: |||
      sum by (%(aggregationLabels)s) (
        rate(container_cpu_usage_seconds_total:labeled{container!="", container!="POD", %(selector)s}[%(rangeInterval)s])
      )
      /
      sum by(%(aggregationLabels)s) (
        container_spec_cpu_shares:labeled{container!="", container!="POD", %(selector)s}
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
