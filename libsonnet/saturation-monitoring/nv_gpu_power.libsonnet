local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

{
  nv_gpu_power: resourceSaturationPoint({
    title: 'GPU Power Consumption',
    severity: 's4',  // NOTE: Do not page on-call SREs until production ready
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findServicesWithTag(tag='nv_gpu'),
    description: |||
      This resource measures GPU power consumption per GPU.

      If this resource is becoming saturated, it may indicate that the fleet needs
      horizontal or vertical scaling.

      For metrics, refer to https://github.com/triton-inference-server/server/blob/main/docs/user_guide/metrics.md#gpu-metrics.

      For scaling, refer to https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/code_suggestions#scalability.
    |||,
    grafana_dashboard_uid: 'sat_nv_gpu_power',
    resourceLabels: ['gpu_uuid', 'pod', 'container'],
    burnRatePeriod: '30m',
    query: |||
      sum by (%(aggregationLabels)s) (
        avg_over_time(nv_gpu_power_usage{%(selector)s}[%(rangeInterval)s])
      )
      /
      sum by (%(aggregationLabels)s) (
        avg_over_time(nv_gpu_power_limit{%(selector)s}[%(rangeInterval)s])
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),
}
