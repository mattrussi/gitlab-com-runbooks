/**
 * This file provides a mapping from Kubernetes node pools to services
 *
 * Ideally, this information would be stored on node pool labels in Terraform
 * (eg, https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gprd/gke-regional.tf)
 * however, changing the labels on a node-pool requires that the node-pool is replaced
 * see https://stackoverflow.com/questions/55275066/add-or-edit-label-on-existing-node-pool-in-gke.
 *
 * Since this is a great deal of effort to add labels, we workaround this issue by adding labels
 * through a side-channel instead.
 */

/**
 * For each environment we specify the labels that
 * The key should match the `type` label for the cluster as specified in Terraform.
 * This label is also exposed via Kube State Metrics on the `kube_node_labels` metric,
 * as the `label_type` label.
 * Each key:value pair hash under that will be added to a recording rule for each cluster.
 */
local additionalLabelsForNodePoolTypes = {
  gprd: [
    {
      /* main gprd regional cluster labels */
      clusters: ['gprd-gitlab-gke'],
      types: {
        default: {
          service_type: 'kube',
          service_tier: 'inf',
          service_stage: 'main',
          service_shard: 'default',
        },
        kas: {
          service_type: 'kas',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        registry: {
          service_type: 'registry',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        'git-https': {
          service_type: 'git',
          service_tier: 'sv',
          service_stage: 'cny',  // Zonal cluster hosts cny stage
          service_shard: 'default',
        },
        'urgent-cpu-bound': {
          service_type: 'sidekiq',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'urgent-cpu-bound',
        },
        shell: {
          service_type: 'git',
          service_tier: 'sv',
          service_stage: 'cny',  // Zonal cluster hosts cny stage
          service_shard: 'default',
        },
        'low-urgency-cpu-bound': {
          service_type: 'sidekiq',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'low-urgency-cpu-bound',
        },
        'urgent-other': {
          service_type: 'sidekiq',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'urgent-other',
        },
        websockets: {
          service_type: 'websockets',
          service_tier: 'sv',
          service_stage: 'cny',  // Zonal cluster hosts cny stage
          service_shard: 'default',
        },
        'memory-bound': {
          service_type: 'sidekiq',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'memory-bound',
        },
        api: {
          service_type: 'api',
          service_tier: 'sv',
          service_stage: 'cny',  // Zonal cluster hosts cny stage
          service_shard: 'default',
        },
        catchall: {
          service_type: 'sidekiq',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'catchall',
        },
        'web-pages': {
          service_type: 'web-pages',
          service_tier: 'sv',
          service_stage: 'cny',
          service_shard: 'default',
        },
      },
    },
    {
      /* gprd zonal clusters */
      clusters: ['gprd-us-east1-b', 'gprd-us-east1-c', 'gprd-us-east1-d'],
      types: {
        default: {
          service_type: 'kube',
          service_tier: 'inf',
          service_stage: 'main',
          service_shard: 'default',
        },
        api: {
          service_type: 'api',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        'git-https': {
          service_type: 'git',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        registry: {
          service_type: 'registry',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        shell: {
          service_type: 'git',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        websockets: {
          service_type: 'websockets',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        'web-pages': {
          service_type: 'web-pages',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
      },
    },
    {
      /* gprd regional org-ci cluster */
      clusters: ['org-ci-gitlab-gke'],
      types: {
        default: {
          service_type: 'ci-runners',
          tier: 'runners',
          service_stage: 'main',
          service_shard: 'default',
        },
      },
    },
  ],
  gstg: [
    {
      /* gstg main regional cluster */
      clusters: ['gstg-gitlab-gke'],
      types: {
        default: {
          service_type: 'kube',
          service_tier: 'inf',
          service_stage: 'main',
          service_shard: 'default',
        },
        kas: {
          service_type: 'kas',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        'urgent-cpu-bound': {
          service_type: 'sidekiq',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'urgent-cpu-bound',
        },
        'low-urgency-cpu-bound': {
          service_type: 'sidekiq',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'low-urgency-cpu-bound',
        },
        'urgent-other': {
          service_type: 'sidekiq',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'urgent-other',
        },
        'memory-bound': {
          service_type: 'sidekiq',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'memory-bound',
        },
        catchall: {
          service_type: 'sidekiq',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'catchall',
        },
        'web-pages': {
          service_type: 'web-pages',
          service_tier: 'sv',
          service_stage: 'cny',
          service_shard: 'default',
        },
      },
    },
    {
      /* gstg zonal clusters */
      clusters: ['gstg-us-east1-b', 'gstg-us-east1-c', 'gstg-us-east1-d'],
      types: {
        default: {
          service_type: 'kube',
          service_tier: 'inf',
          service_stage: 'main',
          service_shard: 'default',
        },
        api: {
          service_type: 'api',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        'git-https': {
          service_type: 'git',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        registry: {
          service_type: 'registry',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        shell: {
          service_type: 'git',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        websockets: {
          service_type: 'websockets',
          service_tier: 'sv',
          service_stage: 'main',
          service_shard: 'default',
        },
        'web-pages': {
          service_type: 'web-pages',
          service_tier: 'sv',
          service_stage: 'cny',
          service_shard: 'default',
        },
      },
    },
  ],
  pre: [
    {
      /* pre regional cluster */
      clusters: ['pre-gitlab-gke'],
      types: {
        'default-1': {
          service_type: 'kube',
          service_tier: 'inf',
          service_stage: 'main',
          service_shard: 'default',
        },
      },
    },
  ],
  ops: [
    {
      /* ops regional cluster */
      clusters: ['ops-gitlab-gke'],
      types: {
        default: {
          service_type: 'kube',
          service_tier: 'inf',
          service_stage: 'main',
          service_shard: 'default',
        },
      },
    },
  ],
};

local kubeNodePoolAdditionalLabelsForType(env, clusterInfo, type, labels) =
  std.map(
    function(clusterName) {
      record: 'gitlab:kube_node_pool_labels',
      labels: labels {
        label_type: type,
        cluster: clusterName,
      },
      expr: '1',
    },
    clusterInfo.clusters
  );

local kubeNodePoolAdditionalLabelsForCluster(env, clusterInfo) =
  std.flatMap(
    function(type)
      local labels = clusterInfo.types[type];
      kubeNodePoolAdditionalLabelsForType(env, clusterInfo, type, labels),
    std.objectFields(clusterInfo.types)
  );

local kubeNodePoolAdditionalLabelsForEnv(env) =
  std.flatMap(
    function(clusterInfo)
      kubeNodePoolAdditionalLabelsForCluster(env, clusterInfo),
    additionalLabelsForNodePoolTypes[env]
  );

local recordingRules = std.flatMap(
  function(env)
    kubeNodePoolAdditionalLabelsForEnv(env),
  std.objectFields(additionalLabelsForNodePoolTypes)
);

local recordingRulesGroupedByCluster = std.foldl(
  function(memo, rule)
    local cluster = rule.labels.cluster;
    if std.objectHas(memo, cluster) then
      memo { [cluster]+: [rule] }
    else
      memo { [cluster]: [rule] },
  recordingRules,
  {},
);


std.foldl(
  function(memo, cluster)
    local filename = 'clusters/' + cluster + '/kube-node-pool-additional-labels.yml';
    memo {
      [filename]: std.manifestYamlDoc({
        groups: [{
          // External monitoring
          name: 'Kube Node Pool Additional Labels: ' + cluster,
          interval: '1m',
          rules: recordingRulesGroupedByCluster[cluster],
        }],
      }),
    },
  std.objectFields(recordingRulesGroupedByCluster),
  {}
)
