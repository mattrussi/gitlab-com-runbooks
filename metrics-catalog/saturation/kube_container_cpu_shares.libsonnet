local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local kubeSaturationHelpers = import 'helpers/kube_saturation_helpers.libsonnet';

{
  kube_container_cpu_shares: resourceSaturationPoint({
    title: 'Kube Container CPU Utilization of Requested Shares',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: kubeSaturationHelpers.kubeProvisionedServices,
    description: |||
      Kubernetes containers are allocated a share of CPU (called "CPU requests" in K8s). When this is exhausted,
      the container may be throttled if the node doesn't have additional allocatable capacity. This is in
      contrast to container CPU quota (called "limits" in K8s), which prevent to use available capacity beyond
      the limit.
    |||,
    grafana_dashboard_uid: 'sat_kube_container_cpu_shares',
    resourceLabels: ['cluster', 'pod', 'container'],
    burnRatePeriod: '5m',
    queryFormatConfig: {
      // container_spec_cpu_shares is exported in millicores, so
      // we need to convert it before using with container_cpu_usage_seconds_total
      containerSpecCpuSharesFactor: 1000,
    },
    query: |||
      rate(container_cpu_usage_seconds_total:labeled{container!="", container!="POD", %(selector)s}[%(rangeInterval)s])
      / on(%(aggregationLabels)s)
      (
        container_spec_cpu_shares:labeled{container!="", container!="POD", %(selector)s}
        /
        %(containerSpecCpuSharesFactor)d
      )
    |||,
    slos: {
      soft: 0.90,
      hard: 0.99,
      alertTriggerDuration: '15m',
    },
  }),
}
