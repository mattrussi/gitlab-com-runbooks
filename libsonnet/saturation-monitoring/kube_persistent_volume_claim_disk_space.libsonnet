local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local selectors = import 'promql/selectors.libsonnet';

{
  kube_persistent_volume_claim_disk_space: resourceSaturationPoint({
    title: 'Kube Persistent Volume Claim Space Utilisation',
    severity: 's2',
    horizontallyScalable: true,
    appliesTo: ['kube'],
    description: |||
      disk space utilization on persistent volume claims.
    |||,
    runbook: 'docs/kube/kubernetes.md',
    grafana_dashboard_uid: 'sat_kube_pvc_disk_space',
    resourceLabels: ['cluster', 'namespace', 'persistentvolumeclaim'],
    useResourceLabelsAsMaxAggregationLabels: true,
    // TODO: keep these resources with the services they're managing, once https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/10249 is resolved
    // do not apply static labels
    staticLabels: {
      type: 'kube',
      tier: 'inf',
      stage: 'main',
    },
    query: |||
      kubelet_volume_stats_used_bytes
      /
      kubelet_volume_stats_capacity_bytes
    |||,
    slos: {
      soft: 0.85,
      hard: 0.90,
    },
    capacityPlanning: {
      saturation_dimensions: [
        { label: 'zoekt', selector: selectors.serializeHash({ persistentvolumeclaim: { re: 'zoekt-.*' } }) },
        { label: 'fluentd', selector: selectors.serializeHash({ persistentvolumeclaim: { re: 'fluentd-.*' } }) },
        { label: 'prom-agent', selector: selectors.serializeHash({ persistentvolumeclaim: { re: 'prom-agent-.*' } }) },
        { label: 'redis-pubsub', selector: selectors.serializeHash({ persistentvolumeclaim: { re: 'redis-data-redis-pubsub-.*' } }) },
        { label: 'redis-registry', selector: selectors.serializeHash({ persistentvolumeclaim: { re: 'redis-data-redis-registry-.*' } }) },
        { label: 'consul', selector: selectors.serializeHash({ persistentvolumeclaim: { re: 'data-consul-.*' } }) },
      ] + [
        {
          label: 'others',
          selector: selectors.serializeHash({ persistentvolumeclaim: { nre: 'zoekt-.*|fluentd-.*|prom-agent-.*|redis-data-redis-pubsub-.*|redis-data-redis-registry-.*|data-consul-.*' } }),
        },
      ],
    },
  }),
}
