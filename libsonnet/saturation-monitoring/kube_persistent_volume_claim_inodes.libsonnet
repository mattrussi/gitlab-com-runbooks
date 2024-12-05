local metrics = import 'servicemetrics/metrics.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = metrics.resourceSaturationPoint;

{
  kube_persistent_volume_claim_inodes: resourceSaturationPoint({
    title: 'Kube Persistent Volume Claim inode Utilisation',
    severity: 's2',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findKubeProvisionedServices(first='web'),
    description: |||
      inode utilization on persistent volume claims.
    |||,
    runbook: 'docs/kube/kubernetes.md',
    grafana_dashboard_uid: 'sat_kube_pvc_inodes',
    resourceLabels: ['persistentvolumeclaim'],
    // TODO: keep these resources with the services they're managing, once https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/10249 is resolved
    // do not apply static labels
    staticLabels: {
      type: 'kube',
      tier: 'inf',
      stage: 'main',
    },
    query: |||
      kubelet_volume_stats_inodes_used:labeled{%(selector)s}
      /
      kubelet_volume_stats_inodes:labeled{%(selector)s}
    |||,
    slos: {
      soft: 0.85,
      hard: 0.90,
    },
  }),
}
