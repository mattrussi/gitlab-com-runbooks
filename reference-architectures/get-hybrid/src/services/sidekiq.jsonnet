local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local sidekiqHelpers = import './lib/sidekiq-helpers.libsonnet';
local perWorkerRecordingRules = (import './lib/sidekiq-per-worker-recording-rules.libsonnet').perWorkerRecordingRules;
local combined = metricsCatalog.combined;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

local highUrgencySelector = { urgency: 'high' };
local lowUrgencySelector = { urgency: 'low' };
local throttledUrgencySelector = { urgency: 'throttled' };
local noUrgencySelector = { urgency: '' };

metricsCatalog.serviceDefinition({
  type: 'sidekiq',
  tier: 'sv',
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.995,
  },
  otherThresholds: {
    // Deployment thresholds are optional, and when they are specified, they are
    // measured against the same multi-burn-rates as the monitoring indicators.
    // When a service is in violation, deployments may be blocked or may be rolled
    // back.
    deployment: {
      apdexScore: 0.995,
      errorRatio: 0.995,
    },
  },
  serviceDependencies: {
    gitaly: true,
    'redis-tracechunks': true,
    'redis-sidekiq': true,
    'redis-cache': true,
    redis: true,
    patroni: true,
    pgbouncer: true,
    praefect: true,
    pvs: true,
    search: true,
    consul: true,
  },
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
      hpaSelector={ horizontalpodautoscaler: 'gitlab-sidekiq-all-in-1-v2' },
      nodeSelector={ eks_amazonaws_com_nodegroup: 'gitlab_sidekiq_pool' },
      deploymentSelector=kubeSelector
    ),
  },
  kubeResources: std.foldl(
    function(memo, shard)
      memo {
        // Deployment tags follow the convention sidekiq-catchall etc
        ['sidekiq-' + shard.name]: {
          kind: 'Deployment',
          containers: [
            'sidekiq',
          ],
        },
      },
    sidekiqHelpers.shards.listAll(),
    {},
  ),
  serviceLevelIndicators: {
    ['shard_' + std.strReplace(shard.name, '-', '_')]: {
      local shardSelector = { shard: shard.name },

      userImpacting: shard.userImpacting,
      featureCategory: 'not_owned',
      team: 'scalability',
      ignoreTrafficCessation: shard.ignoreTrafficCessation,
      upscaleLongerBurnRates: true,

      description: |||
        Aggregation of all jobs for the %(shard)s Sidekiq shard.
      ||| % shardSelector,
      apdex: combined(
        (
          if shard.urgency == null || shard.urgency == 'high' then
            [
              histogramApdex(
                histogram='sidekiq_jobs_completion_seconds_bucket',
                selector=highUrgencySelector,
                satisfiedThreshold=sidekiqHelpers.slos.urgent.executionDurationSeconds,
              ),
              histogramApdex(
                histogram='sidekiq_jobs_queue_duration_seconds_bucket',
                selector=highUrgencySelector,
                satisfiedThreshold=sidekiqHelpers.slos.urgent.queueingDurationSeconds,
              ),
            ] else []
        )
        +
        (
          if shard.urgency == null || shard.urgency == 'low' then
            [
              histogramApdex(
                histogram='sidekiq_jobs_completion_seconds_bucket',
                selector=lowUrgencySelector,
                satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,
              ),
              histogramApdex(
                histogram='sidekiq_jobs_queue_duration_seconds_bucket',
                selector=lowUrgencySelector,
                satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.queueingDurationSeconds,
              ),
            ] else []
        )
        +
        (
          if shard.urgency == null || shard.urgency == 'throttled' then
            [
              histogramApdex(
                histogram='sidekiq_jobs_completion_seconds_bucket',
                selector=throttledUrgencySelector,
                satisfiedThreshold=sidekiqHelpers.slos.throttled.executionDurationSeconds,
              ),
            ] else []
        ) +
        (
          if shard.urgency == null then
            [
              // TODO: remove this once all unattribute jobs are removed
              // Treat `urgency=""` as low urgency jobs.
              histogramApdex(
                histogram='sidekiq_jobs_completion_seconds_bucket',
                selector=noUrgencySelector,
                satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,
              ),
              histogramApdex(
                histogram='sidekiq_jobs_queue_duration_seconds_bucket',
                selector=noUrgencySelector,
                satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.queueingDurationSeconds,
              ),
            ] else []
        )
      ),
// comment
      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector={ le: '+Inf' },
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector={},
      ),

      // Note: these labels will also be included in the
      // intermediate recording rules specified in the
      // `recordingRuleMetrics` stanza above
      significantLabels: ['feature_category', 'queue', 'urgency', 'worker'],

      local slowRequestSeconds =
        if shard.urgency == 'high' then
          sidekiqHelpers.slos.urgent.executionDurationSeconds
        else if shard.urgency == 'low' then
          sidekiqHelpers.slos.lowUrgency.executionDurationSeconds
        else if shard.urgency == 'throttled' then
          sidekiqHelpers.slos.throttled.executionDurationSeconds
        else
          // Default to low urgency threshold
          sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,

      // Consider adding useful links for the environment in the future.
      toolingLinks: [],
    }
    for shard in sidekiqHelpers.shards.listAll()
  } + {
    email_receiver: {
      userImpacting: true,
      severity: 's3',
      featureCategory: 'not_owned',
      team: 'certify',
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

  // Special per-worker recording rules
  extraRecordingRulesPerBurnRate: [
    // Adds per-work queuing/execution apdex, plus error rates etc
    // across multiple burn rates
    perWorkerRecordingRules,
  ],
})
