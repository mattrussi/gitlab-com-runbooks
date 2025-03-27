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

// Routing rule selectors
local urgentCpuBoundSelector = { urgency: 'high', resource_boundary: 'cpu' };
// For urgent non-CPU-bound jobs, we need to use a PromQL compatible approach
local urgentNonCpuSelector = { urgency: 'high', resource_boundary: { ne: 'cpu' } };
// For catching the rest, we'll use a simple non-high-urgency selector
local nonUrgentSelector = { urgency: { ne: 'high' } };


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
  tags: ['rails', 'kube_container_rss'],
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
  recordingRuleMetrics: [
    'sidekiq_jobs_completion_seconds_bucket',
    'sidekiq_jobs_queue_duration_seconds_bucket',
    'sidekiq_jobs_failed_total',
  ],
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

  // A 98% confidence interval will be used for all SLIs on this service
  useConfidenceLevelForSLIAlerts: '98%',

  serviceLevelIndicators: {
    shard_urgent_cpu_bound: {
      userImpacting: true,
      ignoreTrafficCessation: false,
      upscaleLongerBurnRates: true,

      description: |||
        Sidekiq jobs with resource_boundary=cpu and urgency=high
      |||,

      apdex: combined(
        [
          histogramApdex(
            histogram='sidekiq_jobs_completion_seconds_bucket',
            selector=urgentCpuBoundSelector,
            satisfiedThreshold=slos.urgent.executionDurationSeconds,
          ),
          histogramApdex(
            histogram='sidekiq_jobs_queue_duration_seconds_bucket',
            selector=urgentCpuBoundSelector,
            satisfiedThreshold=slos.urgent.queueingDurationSeconds,
          ),
        ]
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector={ le: '+Inf' } + urgentCpuBoundSelector,
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=urgentCpuBoundSelector,
      ),

      significantLabels: ['feature_category', 'queue', 'urgency', 'worker', 'resource_boundary'],

      toolingLinks: [],
    },

    shard_urgent_other: {
      userImpacting: true,
      ignoreTrafficCessation: false,
      upscaleLongerBurnRates: true,

      description: |||
        Sidekiq jobs with urgency=high excluding resource_boundary=cpu
      |||,

      apdex: combined(
        [
          histogramApdex(
            histogram='sidekiq_jobs_completion_seconds_bucket',
            selector=urgentNonCpuSelector,
            satisfiedThreshold=slos.urgent.executionDurationSeconds,
          ),
          histogramApdex(
            histogram='sidekiq_jobs_queue_duration_seconds_bucket',
            selector=urgentNonCpuSelector,
            satisfiedThreshold=slos.urgent.queueingDurationSeconds,
          ),
        ]
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector={ le: '+Inf' } + urgentNonCpuSelector,
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=urgentNonCpuSelector,
      ),

      significantLabels: ['feature_category', 'queue', 'urgency', 'worker', 'resource_boundary'],

      toolingLinks: [],
    },

    shard_catchall: {
      userImpacting: true,
      ignoreTrafficCessation: false,
      upscaleLongerBurnRates: true,

      description: |||
        All other Sidekiq jobs (non-high urgency)
      |||,

      apdex: combined(
        [
          histogramApdex(
            histogram='sidekiq_jobs_completion_seconds_bucket',
            selector=lowUrgencySelector,
            satisfiedThreshold=slos.lowUrgency.executionDurationSeconds,
          ),
          histogramApdex(
            histogram='sidekiq_jobs_queue_duration_seconds_bucket',
            selector=lowUrgencySelector,
            satisfiedThreshold=slos.lowUrgency.queueingDurationSeconds,
          ),
          histogramApdex(
            histogram='sidekiq_jobs_completion_seconds_bucket',
            selector=throttledUrgencySelector,
            satisfiedThreshold=slos.throttled.executionDurationSeconds,
          ),
          // TODO: remove this once all unattribute jobs are removed
          // Treat `urgency=""` as low urgency jobs.
          histogramApdex(
            histogram='sidekiq_jobs_completion_seconds_bucket',
            selector=noUrgencySelector,
            satisfiedThreshold=slos.lowUrgency.executionDurationSeconds,
          ),
          histogramApdex(
            histogram='sidekiq_jobs_queue_duration_seconds_bucket',
            selector=noUrgencySelector,
            satisfiedThreshold=slos.lowUrgency.queueingDurationSeconds,
          ),
        ]
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector={ le: '+Inf' } + nonUrgentSelector,
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=nonUrgentSelector,
      ),

      // Note: these labels will also be included in the
      // intermediate recording rules specified in the
      // `recordingRuleMetrics` stanza above
      significantLabels: ['feature_category', 'queue', 'urgency', 'worker', 'resource_boundary'],

      // Consider adding useful links for the environment in the future.
      toolingLinks: [],
    },
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
  },
})
