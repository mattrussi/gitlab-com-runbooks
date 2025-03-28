local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

// Queue-based selectors for the routing rules
local urgentCpuBoundQueueSelector = { queue: 'urgent_cpu_bound' };
local urgentOtherQueueSelector = { queue: 'urgent_other' };
// For default, use a simpler approach that just selects queues that are not the specific queues
local defaultQueueSelector = { queue: { ne: ['urgent_cpu_bound', 'urgent_other'] } };

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
      // Using a pattern to match all sidekiq HPAs
      hpaSelector={ horizontalpodautoscaler: { re: 'gitlab-sidekiq-.*' } },
      nodeSelector={ workload: 'sidekiq' },
      deploymentSelector=kubeSelector
    ),
  },
  kubeResources: {
    'gitlab-sidekiq-catchall-v2': {
      kind: 'Deployment',
      containers: [
        'sidekiq',
      ],
    },
    'gitlab-sidekiq-urgent-cpu-v2': {
      kind: 'Deployment',
      containers: [
        'sidekiq',
      ],
    },
    'gitlab-sidekiq-urgent-other-v2': {
      kind: 'Deployment',
      containers: [
        'sidekiq',
      ],
    },
  },

  // A 98% confidence interval will be used for all SLIs on this service
  useConfidenceLevelForSLIAlerts: '98%',

  serviceLevelIndicators: {
    urgent_cpu_bound: {
      userImpacting: true,
      ignoreTrafficCessation: false,
      upscaleLongerBurnRates: true,

      description: |||
        Sidekiq jobs in the urgent_cpu_bound queue
      |||,

      apdex: combined(
        [
          histogramApdex(
            histogram='sidekiq_jobs_completion_seconds_bucket',
            selector=urgentCpuBoundQueueSelector,
            satisfiedThreshold=slos.urgent.executionDurationSeconds,
          ),
          histogramApdex(
            histogram='sidekiq_jobs_queue_duration_seconds_bucket',
            selector=urgentCpuBoundQueueSelector,
            satisfiedThreshold=slos.urgent.queueingDurationSeconds,
          ),
        ]
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector={ le: '+Inf' } + urgentCpuBoundQueueSelector,
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=urgentCpuBoundQueueSelector,
      ),

      significantLabels: ['feature_category', 'queue', 'urgency', 'worker', 'resource_boundary'],

      toolingLinks: [],
    },

    urgent_other: {
      userImpacting: true,
      ignoreTrafficCessation: false,
      upscaleLongerBurnRates: true,

      description: |||
        Sidekiq jobs in the urgent_other queue
      |||,

      apdex: combined(
        [
          histogramApdex(
            histogram='sidekiq_jobs_completion_seconds_bucket',
            selector=urgentOtherQueueSelector,
            satisfiedThreshold=slos.urgent.executionDurationSeconds,
          ),
          histogramApdex(
            histogram='sidekiq_jobs_queue_duration_seconds_bucket',
            selector=urgentOtherQueueSelector,
            satisfiedThreshold=slos.urgent.queueingDurationSeconds,
          ),
        ]
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector={ le: '+Inf' } + urgentOtherQueueSelector,
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=urgentOtherQueueSelector,
      ),

      significantLabels: ['feature_category', 'queue', 'urgency', 'worker', 'resource_boundary'],

      toolingLinks: [],
    },

    default: {
      userImpacting: true,
      ignoreTrafficCessation: false,
      upscaleLongerBurnRates: true,

      description: |||
        All other Sidekiq jobs (not in urgent_cpu_bound or urgent_other queues)
      |||,

      apdex: combined(
        [
          histogramApdex(
            histogram='sidekiq_jobs_completion_seconds_bucket',
            selector=defaultQueueSelector,
            satisfiedThreshold=slos.lowUrgency.executionDurationSeconds,
          ),
          histogramApdex(
            histogram='sidekiq_jobs_queue_duration_seconds_bucket',
            selector=defaultQueueSelector,
            satisfiedThreshold=slos.lowUrgency.queueingDurationSeconds,
          ),
        ]
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector={ le: '+Inf' } + defaultQueueSelector,
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=defaultQueueSelector,
      ),

      significantLabels: ['feature_category', 'queue', 'urgency', 'worker', 'resource_boundary'],

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

      toolingLinks: [],
    },
  },
})
