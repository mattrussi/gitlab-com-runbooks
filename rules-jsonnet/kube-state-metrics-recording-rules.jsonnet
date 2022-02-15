local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local objects = import 'utils/objects.libsonnet';
local strings = import 'utils/strings.libsonnet';

//
// EXPERIMENTAL: applying our application label taxonomy to cadvisor
// metrics would help use in attribution of problems.
// These recording rules, while bulky, allow us to apply the
// standard GitLab application labels (type, shard, stage) to
// the metrics we export via cadvisor
//

// TODO: initial spike only contains a small subset of metrics
// to ensure that this approach will work
local cadvisorMetrics = [
  'container_start_time_seconds',
  'container_cpu_cfs_periods_total',
  'container_cpu_cfs_throttled_periods_total',
  'container_cpu_usage_seconds_total',
  'container_memory_cache',
  'container_memory_swap',
  'container_memory_usage_bytes',
  'container_memory_working_set_bytes',
  'container_network_receive_bytes_total',
  'container_network_transmit_bytes_total',
  'container_spec_cpu_period',
  'container_spec_cpu_quota',
  'container_spec_cpu_shares',
  'container_spec_memory_limit_bytes',
];

local kubePodContainerMetrics = [
  'kube_pod_container_status_running',
  'kube_pod_container_resource_limits',
  'kube_pod_container_resource_requests',

  // Kube pod status metrics, useful for measuring pod lifecycles
  'kube_pod_container_status_last_terminated_reason',
  'kube_pod_container_status_ready',
  'kube_pod_container_status_restarts_total',
  'kube_pod_container_status_running',
  'kube_pod_container_status_terminated',
  'kube_pod_container_status_terminated_reason',
  'kube_pod_container_status_waiting',
  'kube_pod_container_status_waiting_reason',
];

local kubeHorizontalPodAutoscalerMetrics = [
  'kube_horizontalpodautoscaler_spec_target_metric',
  'kube_horizontalpodautoscaler_status_condition',
  'kube_horizontalpodautoscaler_status_current_replicas',
  'kube_horizontalpodautoscaler_status_desired_replicas',
  'kube_horizontalpodautoscaler_metadata_generation',
  'kube_horizontalpodautoscaler_spec_max_replicas',
  'kube_horizontalpodautoscaler_spec_min_replicas',
];

local kubeNodeMetrics = [
  'kube_node_status_capacity',
  'kube_node_status_allocatable',
  'kube_node_status_condition',
  'node_schedstat_waiting_seconds_total',
  'node_cpu_seconds_total',
  'node_network_transmit_bytes_total',
  'node_network_receive_bytes_total',
  'node_disk_reads_completed_total',
  'node_disk_writes_completed_total',
  'node_disk_read_bytes_total',
  'node_disk_written_bytes_total',
  'node_disk_read_time_seconds_total',
  'node_disk_write_time_seconds_total',
  'node_load1',
  'node_load5',
  'node_load15',
  'node_vmstat_oom_kill',
];

local ingressMetrics = [
  'nginx_ingress_controller_bytes_sent_count',
  'nginx_ingress_controller_request_duration_seconds_bucket',
  'nginx_ingress_controller_request_duration_seconds_sum',
  'nginx_ingress_controller_response_size_count',
  'nginx_ingress_controller_ingress_upstream_latency_seconds',
  'nginx_ingress_controller_ingress_upstream_latency_seconds_count',
  'nginx_ingress_controller_ingress_upstream_latency_seconds_sum',
  'nginx_ingress_controller_request_duration_seconds_count',
  'nginx_ingress_controller_request_size_bucket',
  'nginx_ingress_controller_response_duration_seconds_bucket',
  'nginx_ingress_controller_bytes_sent_bucket',
  'nginx_ingress_controller_bytes_sent_sum',
  'nginx_ingress_controller_request_size_count',
  'nginx_ingress_controller_response_duration_seconds_sum',
  'nginx_ingress_controller_request_size_sum',
  'nginx_ingress_controller_requests',
  'nginx_ingress_controller_response_duration_seconds_count',
  'nginx_ingress_controller_response_size_bucket',
  'nginx_ingress_controller_response_size_sum',
];

local deploymentMetrics = [
  'kube_deployment_status_replicas_unavailable',
  'kube_deployment_status_replicas_updated',
  'kube_deployment_spec_paused',
  'kube_deployment_spec_replicas',
  'kube_deployment_spec_strategy_rollingupdate_max_surge',
  'kube_deployment_spec_strategy_rollingupdate_max_unavailable',
  'kube_deployment_status_condition',
  'kube_deployment_status_replicas_available',
  'kube_deployment_created',
  'kube_deployment_metadata_generation',
  'kube_deployment_status_observed_generation',
  'kube_deployment_status_replicas',
];

local podLabelJoinExpression(expression) =
  |||
    %(expression)s
    *
    on(environment, cluster, pod) group_left(tier, type, stage, shard, deployment)
    topk by (environment, cluster, pod) (1, kube_pod_labels:labeled{type!=""})
  ||| % {
    expression: expression,
  };

local kubeHorizontalPodAutoscalerLabelJoinExpression(expression) =
  |||
    %(expression)s
    *
    on(environment, cluster, horizontalpodautoscaler) group_left(tier, type, stage, shard)
    topk by (environment, cluster, horizontalpodautoscaler) (1, kube_horizontalpodautoscaler_labels:labeled{type!=""})
  ||| % {
    expression: expression,
  };

// We filter to include only metrics_path="/metrics/cadvisor" series
// and exclude metrics_path="/metrics/resource/v1alpha1" etc
local cadvisorWithLabelNamesExpression(metricName) =
  podLabelJoinExpression('%(metricName)s{metrics_path="/metrics/cadvisor"}' % {
    metricName: metricName,
  });

local nodeLabelJoinExpression(expression) =
  |||
    %(expression)s
    *
    on(environment, cluster, node) group_left(shard, stage, type, tier)
    topk by (environment, cluster, node) (1, kube_node_labels:labeled)
  ||| % {
    expression: expression,
  };

local nginxIngressJoinExpression(expression) =
  |||
    %(expression)s
    *
    on(environment, cluster, ingress) group_left(shard, stage, type, tier)
    topk by (environment, cluster, ingress) (1, kube_ingress_labels:labeled)
  ||| % {
    expression: expression,
  };

local deploymentJoinExpression(expression) =
  |||
    %(expression)s
    *
    on(environment, cluster, deployment) group_left(shard, stage, type, tier)
    topk by (environment, cluster, deployment) (1, kube_deployment_labels:labeled)
  ||| % {
    expression: expression,
  };

local recordingRulesFor(metricName, labels, expression) =
  if expression == null then
    []
  else
    [{
      record: metricName + ':labeled',
      [if labels != {} then 'labels']: labels,
      expr: expression,
    }];

local kubernetesSelectorToKubeStatePromSelector(selector) =
  objects.mapKeyValues(
    function(key, value)
      // Certain labels don't need a prefix
      if key == 'namespace' then
        [key, value]
      else
        ['label_' + key, value],
    selector
  );


local relabel(keyLabel, infoMetric, kubernetesLabelSelector, labelMap) =
  if kubernetesLabelSelector == null then
    null
  else
    local kubernetesSelectorExpression = kubernetesSelectorToKubeStatePromSelector(kubernetesLabelSelector);

    local baseExpression = 'topk by(environment, cluster, %(keyLabel)s) (1, %(infoMetric)s{%(kubernetesSelectorExpression)s})' % {
      kubernetesSelectorExpression: selectors.serializeHash(kubernetesSelectorExpression),
      keyLabel: keyLabel,
      infoMetric: infoMetric,
    };

    local fromLabels = std.objectFields(labelMap);
    local relabels = std.foldl(
      function(memo, labelFrom)
        local labelTo = labelMap[labelFrom];
        |||
          label_replace(
            %(memo)s,
            "%(labelTo)s", "$0", "%(labelFrom)s", ".*"
          )
        ||| % {
          labelTo: labelTo,
          labelFrom: labelFrom,
          memo: strings.indent(memo, 2),
        },
      fromLabels,
      baseExpression
    );

    |||
      group without(%(fromLabels)s) (
        %(relabels)s
      )
    ||| % {
      fromLabels: aggregations.serialize(fromLabels),
      relabels: strings.indent(relabels, 2),
    };

local groupForService(service) =
  local formatConfig = { type: service.type };
  local defaultStaticLabels = { type: service.type, tier: service.tier };
  local kubeLabelSelectors = service.kubeConfig.labelSelectors;

  {
    name: 'kube-state-metrics-recording-rules: %(type)s' % formatConfig,
    interval: '1m',
    rules:
      // Relabel: kube_pod_labels
      recordingRulesFor(
        'kube_pod_labels',
        labels=defaultStaticLabels + kubeLabelSelectors.staticLabels.pod,
        expression=relabel(
          keyLabel='pod',
          infoMetric='kube_pod_labels',
          kubernetesLabelSelector=kubeLabelSelectors.pod,
          labelMap={
            label_stage: 'stage',
            label_shard: 'shard',
            label_deployment: 'deployment',
          }
        )
      )
      +
      // Relabel:kube_horizontalpodautoscaler_labels
      recordingRulesFor(
        'kube_horizontalpodautoscaler_labels',
        labels=defaultStaticLabels + kubeLabelSelectors.staticLabels.hpa,
        expression=relabel(
          keyLabel='horizontalpodautoscaler',
          infoMetric='kube_horizontalpodautoscaler_labels',
          kubernetesLabelSelector=kubeLabelSelectors.hpa,
          labelMap={
            label_stage: 'stage',
            label_shard: 'shard',
          }
        )
      )
      +
      // Relabel: kube_node_labels
      recordingRulesFor(
        'kube_node_labels',
        labels=defaultStaticLabels + kubeLabelSelectors.staticLabels.node,
        expression=relabel(
          keyLabel='node',
          infoMetric='kube_node_labels',
          kubernetesLabelSelector=kubeLabelSelectors.node,
          labelMap={
            service_stage: 'stage',
            service_shard: 'shard',
          }
        )
      )
      +
      // Relabel: kube_ingress_labels
      recordingRulesFor(
        'kube_ingress_labels',
        labels=defaultStaticLabels + kubeLabelSelectors.staticLabels.ingress,
        expression=relabel(
          keyLabel='ingress',
          infoMetric='kube_ingress_labels',
          kubernetesLabelSelector=kubeLabelSelectors.ingress,
          labelMap={
            label_stage: 'stage',
            service_shard: 'shard',
          }
        )
      )
      +
      // Relabel: kube_deployment_labels
      recordingRulesFor(
        'kube_deployment_labels',
        labels=defaultStaticLabels + kubeLabelSelectors.staticLabels.deployment,
        expression=relabel(
          keyLabel='deployment',
          infoMetric='kube_deployment_labels',
          kubernetesLabelSelector=kubeLabelSelectors.deployment,
          labelMap={
            label_stage: 'stage',
            service_shard: 'shard',
          }
        )
      ),
  };

local globalRules =
  /* container_* recording rules */
  std.flatMap(
    function(metricName)
      recordingRulesFor(metricName, labels={}, expression=cadvisorWithLabelNamesExpression(metricName)),
    cadvisorMetrics
  )
  +
  /* kube_pod_container_* recording rules */
  std.flatMap(
    function(metricName)
      recordingRulesFor(metricName, labels={}, expression=podLabelJoinExpression(metricName)),
    kubePodContainerMetrics
  )
  +
  /* kube_horizontalpodautoscaler_* recording rules */
  std.flatMap(
    function(metricName)
      recordingRulesFor(metricName, labels={}, expression=kubeHorizontalPodAutoscalerLabelJoinExpression(metricName)),
    kubeHorizontalPodAutoscalerMetrics
  )
  +
  /* ingress recording rules */
  std.flatMap(
    function(metricName)
      recordingRulesFor(metricName, labels={}, expression=nginxIngressJoinExpression(metricName)),
    ingressMetrics
  )
  +
  /* deployment recording rules */
  std.flatMap(
    function(metricName)
      recordingRulesFor(metricName, labels={}, expression=deploymentJoinExpression(metricName)),
    deploymentMetrics
  )
  +
  /* kube node metrics recording rules */
  std.flatMap(
    function(metricName)
      recordingRulesFor(metricName, labels={}, expression=nodeLabelJoinExpression(metricName)),
    kubeNodeMetrics
  );

local kubeServices = std.filter(function(s) s.provisioning.kubernetes, metricsCatalog.services);

{
  'kube-state-metrics-recording-rules.yml':
    std.manifestYamlDoc({
      groups: [
        groupForService(service)
        for service in kubeServices
      ] + [{
        name: 'kube-state-metrics-recording-rules: global rules',
        interval: '1m',
        rules: globalRules,
      }],
    }),
}
