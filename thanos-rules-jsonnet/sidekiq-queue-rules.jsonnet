local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local minimumOpRate = import 'slo-alerts/minimum-op-rate.libsonnet';
local alerts = import 'alerts/alerts.libsonnet';
local aggregationSetTransformer = import 'servicemetrics/aggregation-set-transformer.libsonnet';
local serviceLevelAlerts = import 'slo-alerts/service-level-alerts.libsonnet';
local stableIds = import 'stable-ids/stable-ids.libsonnet';
local separateGlobalRecordingFiles = (import './lib/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;
local selectors = import 'promql/selectors.libsonnet';

/* TODO: having some sort of criticality label on sidekiq jobs would allow us to
   define different criticality labels for each worker. For now we need to use
   a fixed value, which also needs to be a lower-common-denominator */
local fixedApdexThreshold = 0.90;
local fixedErrorRateThreshold = 0.90;

local minimumSamplesForMonitoringApdex = 1200; /* We don't really care if something runs only very infrequently, but is slow */

// NB: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1324 discusses increases the operation rate
// for some daily sidekiq jobs, to improve the sample rates.
local minimumSamplesForMonitoringErrors = 3; /* Low-frequency jobs may be doing very important things */


local sidekiqThanosAlerts(extraSelector) =
  [
    /**
       * Throttled queues don’t alert on queues SLOs.
       * This means that we will allow jobs to queue up for any amount of time without alerting.
       * One downside is that due to a misconfiguration, we may not be not listening to a throttled
       * queue.
       *
       * Since we don't have an SLO for this we can't use SLOs alert to tell us about this problem.
       * This alert is a safety mechanism. We don’t monitor queueing times, but if there were any
       * queuing jobs
       */
    {
      alert: 'sidekiq_throttled_jobs_enqueued_without_dequeuing',
      expr: |||
        (
          sum by (environment, queue, feature_category, worker) (
            gitlab_background_jobs:queue:ops:rate_1h{%(selector)s}
          ) > 0
        )
        unless
        (
          sum by (environment, queue, feature_category, worker) (
            sli_aggregations:gitlab_sli_sidekiq_execution_apdex_success_total_rate1h{%(selector)s}
          ) > 0
        )
      ||| % {
        selector: selectors.serializeHash({ urgency: { eq: 'throttled' } } + extraSelector),
      },
      'for': '30m',
      labels: {
        type: 'sidekiq',  // Hardcoded because `gitlab_background_jobs:queue:ops:rate_1h` `type` label depends on the sidekiq client `type`
        tier: 'sv',  // Hardcoded because `gitlab_background_jobs:queue:ops:rate_1h` `type` label depends on the sidekiq client `type`
        stage: 'main',
        alert_type: 'cause',
        rules_domain: 'general',
        severity: 's4',
      },
      annotations: {
        title: 'Sidekiq jobs are being enqueued without being dequeued',
        description: |||
          The `{{ $labels.worker}}` worker in the {{ $labels.queue }} queue
          appears to have jobs being enqueued without those jobs being executed.

          This could be the result of a Sidekiq server configuration issue, where
          no Sidekiq servers are configured to dequeue the specific worker.
        |||,
        runbook: 'docs/sidekiq/README.md',
        grafana_dashboard_id: 'sidekiq-worker-detail/sidekiq-worker-detail',
        grafana_variables: 'environment,stage,worker',
        grafana_min_zoom_hours: '6',
        promql_template_1: 'sidekiq_enqueued_jobs_total{environment="$environment", type="$type", stage="$stage", component="$component"}',
      },
    },
    {
      alert: 'SidekiqQueueNoLongerBeingProcessed',
      expr: |||
        (sum by(environment, queue) (gitlab_background_jobs:queue:ops:rate_6h{%(selector)s})> 0.001)
        unless
        (sum by(environment, queue) (sli_aggregations:gitlab_sli_sidekiq_execution_apdex_success_total_rate6h{%(selector)s}) > 0)
      ||| % {
        selector: selectors.serializeHash(extraSelector),
      },
      'for': '20m',
      labels: {
        type: 'sidekiq',
        tier: 'sv',
        stage: 'main',
        alert_type: 'cause',
        rules_domain: 'general',
        severity: 's3',
      },
      annotations: {
        title: 'A Sidekiq queue is no longer being processed.',
        description: 'Sidekiq queue {{ $labels.queue }} in shard {{ $labels.shard }} is no longer being processed.',
        runbook: 'docs/sidekiq/sidekiq-queue-not-being-processed.md',
        grafana_dashboard_id: 'sidekiq-worker-detail/sidekiq-worker-detail',
        grafana_panel_id: stableIds.hashStableId('request-rate'),
        grafana_variables: 'environment,stage,queue',
        grafana_min_zoom_hours: '6',
        promql_template_1: 'sli_aggregations:gitlab_sli_sidekiq_execution_apdex_success_total_rate6h{environment="$environment", queue="$queue"}',
      },
    },
    {
      alert: 'SidekiqWorkerNoLongerBeingProcessed',
      expr: |||
        (sum by(environment, worker) (gitlab_background_jobs:queue:ops:rate_6h{%(selector)s})> 0.001)
        unless
        (sum by(environment, worker) (sli_aggregations:gitlab_sli_sidekiq_execution_apdex_success_total_rate6h{%(selector)s})  > 0)
      ||| % {
        selector: selectors.serializeHash(extraSelector),
      },
      'for': '20m',
      labels: {
        type: 'sidekiq',
        tier: 'sv',
        stage: 'main',
        alert_type: 'cause',
        rules_domain: 'general',
        severity: 's3',
      },
      annotations: {
        title: 'A Sidekiq worker is no longer being processed.',
        description: 'Sidekiq worker {{ $labels.worker }} in shard {{ $labels.shard }} is no longer being processed.',
        runbook: 'docs/sidekiq/sidekiq-queue-not-being-processed.md',
        grafana_dashboard_id: 'sidekiq-worker-detail/sidekiq-worker-detail',
        grafana_panel_id: stableIds.hashStableId('request-rate'),
        grafana_variables: 'environment,stage,worker',
        grafana_min_zoom_hours: '6',
        promql_template_1: 'sli_aggregations:gitlab_sli_sidekiq_execution_apdex_success_total_rate6h{environment="$environment", worker="$worker"}',
      },
    },
    {
      alert: 'SidekiqJobsSkippedTooLong',
      expr: |||
        sum by (environment, worker, action)  (
          rate(
            sidekiq_jobs_skipped_total{%(selector)s}[1h]
            )
          )
          > 0
      ||| % {
        selector: selectors.serializeHash(extraSelector),
      },
      'for': '3h',
      labels: {
        team: 'scalability',
        severity: 's4',
        alert_type: 'cause',
      },
      annotations: {
        title: 'Sidekiq jobs from `{{ $labels.worker }}` are intentionally being `{{ $labels.action }}` for too long',
        description: |||
          Sidekiq jobs from `{{ $labels.worker }}` are being `{{ $labels.action }}` indefinitely via feature flag `run_sidekiq_jobs_<worker_name>` or `drop_sidekiq_jobs_<worker_name>`. This feature flag might be used during an incident and forgotten
          to be removed.
          Ignore if this is still intentionally left.

          Run `/chatops run feature list --match run_sidekiq_jobs` and `/chatops run feature list --match drop_sidekiq_jobs` to list currently used feature flags.
        |||,
        grafana_dashboard_id: 'sidekiq-worker-detail',
        grafana_panel_id: stableIds.hashStableId('jobs-skipped'),
        grafana_min_zoom_hours: '6',
        grafana_variables: 'environment,worker',
      },
    },
    {
      alert: serviceLevelAlerts.nameSLOViolationAlert('sidekiq', 'WorkerExecution', 'ApdexSLOViolation'),
      expr: |||
        (
          (
            sli_aggregations:gitlab_sli_sidekiq_execution_apdex_success_total_rate6h{%(selector)s}
            /
            sli_aggregations:gitlab_sli_sidekiq_execution_apdex_total_rate6h{%(selector)s}
          ) < %(apdexThreshold)s
          and
          (
            sli_aggregations:gitlab_sli_sidekiq_execution_apdex_success_total_rate30m{%(selector)s}
            /
            sli_aggregations:gitlab_sli_sidekiq_execution_apdex_total_rate30m{%(selector)s}
          ) < %(apdexThreshold)s
        )
        and on (env, environment, tier, type, stage, shard, queue, feature_category, urgency, worker)
        (
          sum by (env, environment, tier, type, stage, shard, queue, feature_category, urgency, worker) (
            sli_aggregations:gitlab_sli_sidekiq_execution_total_rate6h{%(selector)s}
          ) >= %(minimumOpRate)s
        )
      ||| % {
        selector: selectors.serializeHash(extraSelector),
        minimumOpRate: minimumOpRate.calculateFromSamplesForDuration('6h', minimumSamplesForMonitoringApdex),
        apdexThreshold: fixedApdexThreshold,
      },
      'for': '1h',
      labels: {
        aggregation: 'sidekiq_execution',
        alert_class: 'slo_violation',
        alert_type: 'symptom',
        rules_domain: 'general',
        severity: 's4',
        sli_type: 'apdex',
        slo_alert: 'yes',
        window: '6h',
      },
      annotations: {
        title: 'The `{{ $labels.worker }}` Sidekiq worker, `{{ $labels.stage }}` stage, has an apdex violating SLO',
        description: |||
          The `{{ $labels.worker }}` worker is not meeting its apdex SLO.

          Currently the apdex value is {{ $value | humanizePercentage }}.
        |||,
        runbook: 'docs/sidekiq/README.md',
        grafana_dashboard_id: 'sidekiq-worker-detail/sidekiq-worker-detail',
        grafana_panel_id: stableIds.hashStableId('execution-apdex'),
        grafana_variables: 'environment,stage,worker',
        grafana_min_zoom_hours: '6',
      },
    },
    {
      alert: serviceLevelAlerts.nameSLOViolationAlert('sidekiq', 'WorkerExecution', 'ErrorSLOViolation'),
      expr: |||
        (
          (
            sli_aggregations:gitlab_sli_sidekiq_execution_error_total_rate6h{%(selector)s}
            /
            sli_aggregations:gitlab_sli_sidekiq_execution_total_rate6h{%(selector)s}
          ) < %(errorThreshold)s
          and
          (
            sli_aggregations:gitlab_sli_sidekiq_execution_error_total_rate30m{%(selector)s}
            /
            sli_aggregations:gitlab_sli_sidekiq_execution_total_rate30m{%(selector)s}
          ) < %(errorThreshold)s
        )
        and on (env, environment, tier, type, stage, shard, queue, feature_category, urgency, worker)
        (
          sum by (env, environment, tier, type, stage, shard, queue, feature_category, urgency, worker) (
            sli_aggregations:gitlab_sli_sidekiq_execution_total_rate6h{%(selector)s}
          ) >= %(errorThreshold)s
        )
      ||| % {
        selector: selectors.serializeHash(extraSelector),
        minimumOpRate: minimumOpRate.calculateFromSamplesForDuration('6h', minimumSamplesForMonitoringErrors),
        errorThreshold: fixedErrorRateThreshold,
      },
      'for': '1h',
      labels: {
        aggregation: 'sidekiq_execution',
        alert_class: 'slo_violation',
        alert_type: 'symptom',
        rules_domain: 'general',
        severity: 's4',
        sli_type: 'error',
        slo_alert: 'yes',
        window: '6h',
      },
      annotations: {
        title: 'The `{{ $labels.worker }}` Sidekiq worker, `{{ $labels.stage }}` stage, has an error rate violating SLO',
        description: |||
          The `{{ $labels.worker }}` worker is not meeting its error-rate SLO.

          Currently the error-rate is {{ $value | humanizePercentage }}.
        |||,
        runbook: 'docs/sidekiq/README.md',
        grafana_dashboard_id: 'sidekiq-worker-detail/sidekiq-worker-detail',
        grafana_panel_id: stableIds.hashStableId('error-ratio'),
        grafana_variables: 'environment,stage,worker',
        grafana_min_zoom_hours: '6',
      },
    },
  ];


local rules(extraSelector) = {
  groups:
    aggregationSetTransformer.generateRecordingRuleGroups(
      sourceAggregationSet=aggregationSets.sidekiqWorkerQueueSourceSLIs { selector+: extraSelector },
      targetAggregationSet=aggregationSets.sidekiqWorkerQueueSLIs,
      extrasForGroup={ partial_response_strategy: 'warn' },
    )
    + [{
      name: 'Sidekiq Aggregated Thanos Alerts',
      partial_response_strategy: 'warn',
      interval: '1m',
      rules: alerts.processAlertRules(sidekiqThanosAlerts(extraSelector)),
    }],
};

separateGlobalRecordingFiles(function(selector) {
  'sidekiq-alerts': std.manifestYamlDoc(rules(selector)),
})
