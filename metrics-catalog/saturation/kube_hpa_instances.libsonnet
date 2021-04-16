local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local sidekiqHelpers = import './services/lib/sidekiq-helpers.libsonnet';

{
  kube_hpa_instances: resourceSaturationPoint({
    title: 'HPA Instances',
    severity: 's2',
    horizontallyScalable: true,
    appliesTo: ['kube'],
    description: |||
      This measures the HPA that manages our Deployments. If we are running low on
      ability to scale up by hitting our maximum HPA Pod allowance, we will have
      fully saturated this service.
    |||,
    runbook: 'docs/uncategorized/kubernetes.md#hpascalecapability',
    grafana_dashboard_uid: 'sat_kube_hpa_instances',
    resourceLabels: ['hpa'],
    // TODO: keep these resources with the services they're managing, once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10249 is resolved
    // do not apply static labels
    staticLabels: {
      type: 'kube',
      tier: 'inf',
      stage: 'main',
    },
    // TODO: remove label-replace ugliness once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10249 is resolved
    // TODO: add %(selector)s once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10249 is resolved
    query: |||
      label_replace(
        label_replace(
          kube_hpa_status_desired_replicas{%(selector)s, hpa!~"gitlab-sidekiq-(%(ignored_sidekiq_shards)s)-v1"}
          /
          kube_hpa_spec_max_replicas,
          "stage", "cny", "hpa", "gitlab-cny-.*"
        ),
        "type", "$1", "hpa", "gitlab-(?:cny-)?(\\w+)"
      )
    |||,
    queryFormatConfig: {
      // Ignore non-autoscaled shards and throttled shards
      ignored_sidekiq_shards: std.join('|', sidekiqHelpers.shards.listFiltered(function(shard) !shard.autoScaling || shard.urgency == 'throttled')),
    },
    slos: {
      soft: 0.95,
      hard: 0.90,
      alertTriggerDuration: '25m',
    },
  }),
}
