local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local kubeSaturationHelpers = import 'helpers/kube_saturation_helpers.libsonnet';

{
  kube_container_memory: resourceSaturationPoint({
    title: 'Kube Container Memory Utilization',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: kubeSaturationHelpers.kubeProvisionedServices,
    description: |||
      Records the total memory utilization for containers for this service, as a percentage of
      the memory limit as configured through Kubernetes.
    |||,
    grafana_dashboard_uid: 'sat_kube_container_memory',
    resourceLabels: ['pod', 'container'],
    // burnRatePeriod: '5m',
    query: |||
      container_memory_working_set_bytes:labeled{container!="", container!="POD", %(selector)s}
      /
      (container_spec_memory_limit_bytes:labeled{container!="", container!="POD", %(selector)s} > 0)
    |||,
    slos: {
      soft: 0.90,
      hard: 0.99,
      alertTriggerDuration: '15m',
    },
  }),
}
