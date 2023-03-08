// This config adapted from
// https://github.com/thanos-io/thanos/blob/main/mixin/config.libsonnet
{
  local thanos = self,
  // TargetGroups is a way to help mixin users to add high level target grouping to their alerts and dashboards.
  // With the help of TargetGroups you can use a single observability stack to monitor several Thanos instances.
  // The key in the key-value pair will be used as "label name" in the alerts and variable name in the dashboards.
  // The value in the key-value pair will be used as a query to fetch available values for the given label name.
  targetGroups+:: {
    // For example for given following groups,
    // namespace: 'thanos_status',
    // cluster: 'find_mi_cluster_bitte',
    // zone: 'an_i_in_da_zone',
    // region: 'losing_my_region',
    // will generate queriers for the alerts as follows:
    //  (
    //     sum by (cluster, namespace, region, zone, job) (rate(thanos_compact_group_compactions_failures_total{job=~"thanos-compact.*"}[5m]))
    //   /
    //     sum by (cluster, namespace, region, zone, job) (rate(thanos_compact_group_compactions_total{job=~"thanos-compact.*"}[5m]))
    //   * 100 > 5
    //   )
    //
    // AND for the dashborads:
    //
    // sum by (cluster, namespace, region, zone, job) (rate(thanos_compact_group_compactions_failures_total{cluster=\"$cluster\", namespace=\"$namespace\", region=\"$region\", zone=\"$zone\", job=\"$job\"}[$interval]))
    // /
    // sum by (cluster, namespace, region, zone, job) (rate(thanos_compact_group_compactions_total{cluster=\"$cluster\", namespace=\"$namespace\", region=\"$region\", zone=\"$zone\", job=\"$job\"}[$interval]))
  },
  query+:: {
    selector: 'job=~".*thanos-query.*"',
    title: '%(prefix)sQuery' % $.dashboard.prefix,
  },
  queryFrontend+:: {
    selector: 'job=~".*thanos-query-frontend.*"',
    title: '%(prefix)sQuery Frontend' % $.dashboard.prefix,
  },
  store+:: {
    selector: 'job=~".*thanos-store.*"',
    title: '%(prefix)sStore' % $.dashboard.prefix,
  },
  receive:: null,  // We don't handle receive endpoints yet. Fix in https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/17115
  rule+:: {
    selector: 'job=~"thanos"',  // Fix: see https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/17377
    title: '%(prefix)sRule' % $.dashboard.prefix,
  },
  compact+:: {
    selector: 'job=~"thanos-.*-compactor"',  // Fix: see https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/17377
    title: '%(prefix)sCompact' % $.dashboard.prefix,
  },
  sidecar+:: {
    selector: '',  //  Fix: see https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/17377
    thanosPrometheusCommonDimensions: 'namespace, pod',
    title: '%(prefix)sSidecar' % $.dashboard.prefix,
  },
  bucketReplicate:: null,  // We don't do bucket replication yet
  dashboard+:: {
    prefix: 'Thanos / ',
    tags: ['thanos-mixin'],
    timezone: 'UTC',
    selector: ['job=~"thanos.*"'] + ['%s="$%s"' % [level, level] for level in std.objectFields(thanos.targetGroups)],
    dimensions: ['%s' % level for level in std.objectFields(thanos.targetGroups)],

    overview+:: {
      title: '%(prefix)sOverview' % $.dashboard.prefix,
      selector: std.join(', ', thanos.dashboard.selector),
      dimensions: std.join(', ', thanos.dashboard.dimensions + ['job']),
    },
  },
}
