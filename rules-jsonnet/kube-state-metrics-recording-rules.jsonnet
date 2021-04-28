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
  'container_spec_memory_limit_bytes',
];

local kubePodContainerMetrics = [
  'kube_pod_container_status_running',
  'kube_pod_container_resource_limits_cpu_cores',
  'kube_pod_container_resource_limits_memory_bytes',
  'kube_pod_container_resource_requests_cpu_cores',
  'kube_pod_container_resource_requests_memory_bytes',

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

local kubeHPAMetrics = [
  'kube_hpa_spec_target_metric',
  'kube_hpa_status_condition',
  'kube_hpa_status_current_replicas',
  'kube_hpa_status_desired_replicas',
  'kube_hpa_metadata_generation',
  'kube_hpa_spec_max_replicas',
  'kube_hpa_spec_min_replicas',
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

local podLabelJoinExpression(expression) =
  |||
    min without(label_queue_pod_name, label_stage, label_type, label_deployment)
    (
      label_replace(
        label_replace(
          label_replace(
            label_replace(
              %(expression)s
              *
              on(pod, cluster) group_left(label_type, label_stage, label_queue_pod_name, label_deployment)
              topk by (pod, cluster, label_type, label_stage, label_queue_pod_name, label_deployment) (1, kube_pod_labels{
                label_type!=""
              }),
              "shard", "$1", "label_queue_pod_name", "(.*)"
            ),
            "stage", "$1", "label_stage", "(.*)"
          ),
          "type", "$1", "label_type", "(.*)"
        ),
        "deployment", "$1", "label_deployment", "(.*)"
      )
    )
  ||| % {
    expression: expression,
  };

local kubeHPALabelJoinExpression(expression) =
  |||
    min without(label_shard, label_stage, label_type, label_tier)
    (
      label_replace(
        label_replace(
          label_replace(
            label_replace(
              %(expression)s
              *
              on(hpa, cluster) group_left(label_shard, label_stage, label_type, label_tier)
              topk by (hpa, cluster) (1, kube_hpa_labels{
                label_type!=""
              }),
              "shard", "$1", "label_shard", "(.*)"
            ),
            "stage", "$1", "label_stage", "(.*)"
          ),
          "type", "$1", "label_type", "(.*)"
        ),
        "tier", "$1", "label_tier", "(.*)"
      )
    )
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
    on(node) group_left(shard, stage, type, tier)
    topk by (node) (1, kube_node_labels:labeled)
  ||| % {
    expression: expression,
  };

local recordingRuleFor(metricName, expression) =
  {
    record: metricName + ':labeled',
    expr: expression,
  };

local rules = {
  groups: [{
    name: 'kube-state-metrics-recording-rules',
    interval: '1m',
    rules: [
      /* container_* recording rules */
      recordingRuleFor(metricName, cadvisorWithLabelNamesExpression(metricName))
      for metricName in cadvisorMetrics
    ] + [
      /* kube_pod_container_* recording rules */
      recordingRuleFor(metricName, podLabelJoinExpression(metricName))
      for metricName in kubePodContainerMetrics
    ] + [
      /* kube_hpa_* recording rules */
      recordingRuleFor(metricName, kubeHPALabelJoinExpression(metricName))
      for metricName in kubeHPAMetrics
    ] + [
      recordingRuleFor(
        'kube_node_labels',
        |||
          group without(service_type, service_tier, service_shard, service_stage)
          (
            label_replace(
              label_replace(
                label_replace(
                  label_replace(
                    kube_node_labels * on(label_type)
                    group_left(service_type, service_tier, service_shard, service_stage)
                    topk by(label_type) (1, gitlab:kube_node_pool_labels),
                    "type", "$0", "service_type", ".*"
                  ),
                  "tier", "$0", "service_tier", ".*"
                ),
                "shard", "$0", "service_shard", ".*"
              ),
              "stage", "$0", "service_stage", ".*"
            )
          )
        |||
      ),
    ] + [
      /* node_* recording rules */
      recordingRuleFor(metricName, nodeLabelJoinExpression(metricName))
      for metricName in kubeNodeMetrics
    ],
  }],
};

{
  'kube-state-metrics-recording-rules.yml': std.manifestYamlDoc(rules),
}
