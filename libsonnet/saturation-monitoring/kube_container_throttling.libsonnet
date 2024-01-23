local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

{
  kube_container_throttling: resourceSaturationPoint({
    title: 'Kube container throttling',
    severity: 's3',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findKubeProvisionedServices(first='web'),
    description: |||
      Kube container throttling

      A container will be throttled if it reaches the configured cpu limit for the
      horizontal pod autoscaler. Or when other containers on the node are overutilizing
      the the CPU.

      To get around this, consider increasing the limit for this workload, taking
      into consideration the requested resources.
    |||,
    grafana_dashboard_uid: 'kube_container_throttling',
    burnRatePeriod: '5m',
    quantileAggregation: 0.99,  // Using a quantile, rather than a max, so we filter out the worst pods.
    resourceLabels: ['pod', 'container'],
    query: |||
      avg by (%(aggregationLabels)s)(
        rate(container_cpu_cfs_throttled_periods_total:labeled{container!="", %(selector)s}[%(rangeInterval)s])
        /
        rate(container_cpu_cfs_periods_total:labeled{container!="", %(selector)s}[%(rangeInterval)s])
      )
    |||,
    slos: {
      soft: 0.40,
      hard: 0.50,
      alertTriggerDuration: '10m',
    },
  }),
}
