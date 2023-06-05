local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

{
  nv_gpu_memory: resourceSaturationPoint({
    title: 'GPU Memory Utilization',
    severity: 's4',  // NOTE: Do not page on-call SREs until production ready
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findServicesWithTag(tag='nv_gpu'),
    description: |||
      This resource measures GPU memory utilization per GPU.

      If this resource is becoming saturated, it may indicate that the fleet needs
      horizontal or vertical scaling.

      For metrics, refer to https://github.com/triton-inference-server/server/blob/main/docs/user_guide/metrics.md#gpu-metrics.

      For scaling, refer to https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/code_suggestions#scalability.
    |||,
    grafana_dashboard_uid: 'sat_nv_gpu_memory',
    resourceLabels: ['gpu_uuid', 'pod', 'container'],
    query: |||
      sum by (%(aggregationLabels)s) (
        nv_gpu_memory_used_bytes{%(selector)s}
      )
      /
      sum by (%(aggregationLabels)s) (
        nv_gpu_memory_total_bytes{%(selector)s}
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),
}
