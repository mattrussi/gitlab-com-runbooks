local aggregationSets = (import 'metrics-config.libsonnet').aggregationSets;
local alerts = import 'alerts/alerts.libsonnet';
local multiburnExpression = import 'mwmbr/expression.libsonnet';
local stableIds = import 'stable-ids/stable-ids.libsonnet';

// For the first iteration, all sidekiq workers will have the samne
// error budget. In future, we may introduce a criticality attribute to
// allow jobs to have different error budgets based on criticality
local monthlyErrorRateBudget = (1 - 0.99);  // 99% of sidekiq executions should succeed
local monthlyApdexScoreBudget = 0.99;  // 99% of sidekiq executions should succeed

// For now, only include jobs that run 0.1 times per second, or 6 times a minute
// in the monitoring. This is to avoid low-volume, noisy alerts
local minimumOperationRateForMonitoring = 6 / 60;

local sidekiqSLOAlert(alertname, expr, grafanaPanelStableId, metricName, alertDescription, metricDescription) =
  {
    alert: alertname,
    expr: expr,
    'for': '2m',
    labels: {
      alert_type: 'symptom',
      rules_domain: 'general',
      severity: 's4',
      slo_alert: 'yes',
    },
    annotations: {
      title: 'The `{{ $labels.worker }}` worker, `{{ $labels.stage }}` stage, has %s' % [alertDescription],
      description: 'Currently the %s is {{ $value | humanizePercentage }}.' % [metricDescription],
      runbook: 'docs/sidekiq/README.md',
      grafana_dashboard_id: 'sidekiq-worker-detail/sidekiq-worker-detail',
      grafana_panel_id: stableIds.hashStableId(grafanaPanelStableId),
      grafana_variables: 'environment,stage,worker',
      grafana_min_zoom_hours: '6',
      promql_template_1: '%s{environment="$environment", type="$type", stage="$stage", component="$component"}' % [metricName],
    },
  };

// generateAlerts configures the alerting rules for sidekiq jobs
// For the first iteration, things are fairly basic:
// 1. fixed error rates - 1% error budget
// 2. fixed operation rates - jobs need to run on average 4 times an hour to be
//    included in these alerts
local generateAlerts() =
  [
    sidekiqSLOAlert(
      alertname='sidekiq_background_job_error_ratio_burn_rate_slo_out_of_bounds',
      expr=multiburnExpression.multiburnRateErrorExpression(
        aggregationSet=aggregationSets.sidekiqWorkerExecutionSLIs,
        metricSelectorHash={},
        minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
        operationRateWindowDuration='6h',
        thresholdSLOValue=monthlyErrorRateBudget,
      ),
      grafanaPanelStableId='error-ratio',
      metricName='gitlab_background_jobs:execution:error:ratio_1h',
      alertDescription='an error rate outside of SLO',
      metricDescription='error rate'
    ),
    sidekiqSLOAlert(
      alertname='sidekiq_background_job_execution_apdex_ratio_burn_rate_slo_out_of_bounds',
      expr=multiburnExpression.multiburnRateApdexExpression(
        aggregationSet=aggregationSets.sidekiqWorkerExecutionSLIs,
        metricSelectorHash={},
        minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
        thresholdSLOValue=monthlyApdexScoreBudget,
      ),
      grafanaPanelStableId='execution-apdex',
      metricName='gitlab_background_jobs:execution:apdex:ratio_1h',
      alertDescription='a execution latency outside of SLO',
      metricDescription='apdex score',
    ),
    sidekiqSLOAlert(
      alertname='sidekiq_background_job_queue_apdex_ratio_burn_rate_slo_out_of_bounds',
      expr=multiburnExpression.multiburnRateApdexExpression(
        aggregationSet=aggregationSets.sidekiqWorkerQueueSLIs,
        metricSelectorHash={},
        minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
        operationRateWindowDuration='6h',
        thresholdSLOValue=monthlyApdexScoreBudget,
      ),
      grafanaPanelStableId='queue-apdex',
      metricName='gitlab_background_jobs:queue:apdex:ratio_1h',
      alertDescription='a queue latency outside of SLO',
      metricDescription='apdex score',
    ),
  ];

local rules = {
  groups: [{
    name: 'Sidekiq Per Worker Alerting',
    interval: '1m',
    rules:
      std.map(alerts.processAlertRule, generateAlerts()),
  }],
};

{
  'sidekiq-worker-key-metrics.yml': std.manifestYamlDoc(rules),
}
