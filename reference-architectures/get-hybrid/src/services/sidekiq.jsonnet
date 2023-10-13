local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

local highUrgencySelector = { urgency: 'high' };
local lowUrgencySelector = { urgency: 'low' };
local throttledUrgencySelector = { urgency: 'throttled' };
local noUrgencySelector = { urgency: '' };
local sliLibrary = import 'gitlab-slis/library.libsonnet';

local slos = {
  urgent: {
    queueingDurationSeconds: 10,
    executionDurationSeconds: 10,
  },
  lowUrgency: {
    queueingDurationSeconds: 60,
    executionDurationSeconds: 300,
  },
  throttled: {
    // Throttled jobs don't have a queuing duration,
    // so don't add one here!
    executionDurationSeconds: 300,
  },
};

metricsCatalog.serviceDefinition({
  type: 'sidekiq',
  tier: 'sv',
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.995,
  },
  otherThresholds: {},
  serviceDependencies: {},
  provisioning: {
    kubernetes: true,
    vms: false,
  },
  // Use recordingRuleMetrics to specify a set of metrics with known high
  // cardinality. The metrics catalog will generate recording rules with
  // the appropriate aggregations based on this set.
  // Use sparingly, and don't overuse.
  recordingRuleMetrics: (
    sliLibrary.get('sidekiq_execution').recordingRuleMetrics
    + sliLibrary.get('sidekiq_queueing').recordingRuleMetrics
  ),
  kubeConfig: {
    local kubeSelector = { app: 'sidekiq' },
    labelSelectors: kubeLabelSelectors(
      podSelector=kubeSelector,
      ingressSelector=null,
      // TODO: use a better selector for Sidekiq HPAs: https://gitlab.com/gitlab-com/runbooks/-/issues/87
      hpaSelector={ horizontalpodautoscaler: 'gitlab-sidekiq-all-in-1-v2' },
      nodeSelector={ workload: 'sidekiq' },
      deploymentSelector=kubeSelector
    ),
  },
  kubeResources: {
    'gitlab-sidekiq-all-in-1-v2': {
      kind: 'Deployment',
      containers: [
        'sidekiq',
      ],
    },
  },
  serviceLevelIndicators: {
    email_receiver: {
      userImpacting: true,
      severity: 's3',
      featureCategory: 'not_owned',
      description: |||
        Monitors ratio between all received emails and received emails which
        could not be processed for some reason.
      |||,

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_count',
        selector={ worker: { re: 'EmailReceiverWorker|ServiceDeskEmailReceiverWorker' } }
      ),

      errorRate: rateMetric(
        counter='gitlab_transaction_event_email_receiver_error_total',
        selector={ 'error': { ne: 'Gitlab::Email::AutoGeneratedEmailError' } }
      ),

      monitoringThresholds+: {
        errorRatio: 0.7,
      },

      significantLabels: ['error'],

      // Consider adding useful links for the environment in the future.
      toolingLinks: [],
    },
  } + sliLibrary.get('sidekiq_execution').generateServiceLevelIndicator({ external_dependencies: { ne: 'yes' } }, {
    serviceAggregation: true,
  }) + sliLibrary.get('sidekiq_queueing').generateServiceLevelIndicator({ external_dependencies: { ne: 'yes' } }, {
    serviceAggregation: false,  // Don't add this to the request rate of the service
    featureCategory: 'not_owned',
  }),
})
