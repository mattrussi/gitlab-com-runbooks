local metrics = import 'servicemetrics/metrics.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = metrics.resourceSaturationPoint;

{
  kube_persistent_volume_claim_disk_space: resourceSaturationPoint({
    title: 'Kube Persistent Volume Claim Space Utilisation',
    severity: 's2',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findKubeProvisionedServices(first='web'),
    description: |||
      disk space utilization on persistent volume claims.
    |||,
    runbook: 'docs/kube/kubernetes.md',
    grafana_dashboard_uid: 'sat_kube_pvc_disk_space',
    resourceLabels: ['cluster', 'namespace', 'persistentvolumeclaim'],
    // TODO: keep these resources with the services they're managing, once https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/10249 is resolved
    // do not apply static labels
    staticLabels: {
      type: 'kube',
      tier: 'inf',
      stage: 'main',
    },
    query: |||
      kubelet_volume_stats_used_bytes:labeled{%(selector)s}
      /
      kubelet_volume_stats_capacity_bytes:labeled{%(selector)s}
    |||,
    slos: {
      soft: 0.85,
      hard: 0.90,
    },
  }),
}
