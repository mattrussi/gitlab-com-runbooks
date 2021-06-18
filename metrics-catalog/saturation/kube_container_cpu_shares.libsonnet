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
      The Kube Container CPU Utilization is close to the amount of CPU Shares requested for the
      {{ $labels.type }} service ({{ $labels.stage }} stage). This could lead to over-utilization of the nodes.
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
