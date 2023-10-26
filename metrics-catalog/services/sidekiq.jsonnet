local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local sidekiqHelpers = import './lib/sidekiq-helpers.libsonnet';
local perWorkerRecordingRules = (import './lib/sidekiq-per-worker-recording-rules.libsonnet').perWorkerRecordingRules;
local combined = metricsCatalog.combined;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
local sliLibrary = import 'gitlab-slis/library.libsonnet';

local baseSelector = { type: 'sidekiq' };
local highUrgencySelector = { urgency: 'high' };
local lowUrgencySelector = { urgency: 'low' };
local throttledUrgencySelector = { urgency: 'throttled' };

metricsCatalog.serviceDefinition({
  type: 'sidekiq',
  tier: 'sv',
  tags: ['rails'],

  // overrides monitoringThresholds for specific shards and SLIs
  monitoring: {
    shard: {
      enabled: true,
      overrides: {
        sidekiq_execution: {
          'urgent-authorized-projects': {
            apdexScore: 0.98,
          },
        },
        sidekiq_queueing: {
          'urgent-other': {
            apdexScore: 0.97,
          },
        },
      },
    },
  },

  contractualThresholds: {
    apdexRatio: 0.9,
    errorRatio: 0.1,
  },
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
    'redis-cluster-queues-meta': true,
    'redis-cluster-cache': true,
    redis: true,
    patroni: true,
    pgbouncer: true,
    praefect: true,
    pvs: true,
    search: true,
    consul: true,
    'google-cloud-storage': true,
  },
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
    labelSelectors: kubeLabelSelectors(
      ingressSelector=null,  // no ingress for sidekiq
      nodeSelector={ type: 'sidekiq' },
      // Sidekiq nodes don't present a stage label at present, so\
      // we hardcode to main stage
      nodeStaticLabels={ stage: 'main' },
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
  serviceLevelIndicators: sliLibrary.get('sidekiq_execution').generateServiceLevelIndicator(baseSelector { external_dependencies: { ne: 'yes' } }, {
    // TODO: For now, only sidekiq execution is considered towards service aggregation
    // which means queueing is not part of the service aggregation & SLA.
    // Future plan is to be able to specify either apdex, errors, or ops to be included in service aggregaiton.
    // See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2423.
    serviceAggregation: true,
    severity: 's2',
    toolingLinks: [
      // Improve sentry link once https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/532 arrives
      toolingLinks.sentry(projectId=3, type='sidekiq', variables=['environment', 'stage']),
      toolingLinks.kibana(title='Sidekiq execution', index='sidekiq_execution', type='sidekiq'),
    ],
    trafficCessationAlertConfig: sidekiqHelpers.shardTrafficCessationAlertConfig,
  }) + sliLibrary.get('sidekiq_queueing').generateServiceLevelIndicator(baseSelector { external_dependencies: { ne: 'yes' } }, {
    serviceAggregation: false,  // Don't add this to the request rate of the service
    severity: 's2',
    toolingLinks: [
      toolingLinks.kibana(title='Sidekiq queueing', index='sidekiq_queueing', type='sidekiq'),
    ],
    featureCategory: 'not_owned',
    trafficCessationAlertConfig: sidekiqHelpers.shardTrafficCessationAlertConfig,
  }) + sliLibrary.get('sidekiq_execution_with_external_dependency').generateServiceLevelIndicator(baseSelector { external_dependencies: { eq: 'yes' } }, {
    serviceAggregation: false,  // Don't add this to the request rate of the service
    shardLevelMonitoring: false,
    severity: 's3',
    monitoringThresholds+: {
      errorRatio: 0.9,
    },
    trafficCessationAlertConfig: sidekiqHelpers.shardTrafficCessationAlertConfig,
  }) + sliLibrary.get('sidekiq_queueing_with_external_dependency').generateServiceLevelIndicator(baseSelector { external_dependencies: { eq: 'yes' } }, {
    serviceAggregation: false,  // Don't add this to the request rate of the service
    shardLevelMonitoring: false,
    team: 'sre_reliability',
    severity: 's3',
  }) + sliLibrary.get('llm_completion').generateServiceLevelIndicator({}, {
    serviceAggregation: false,
    shardLevelMonitoring: false,
    severity: 's4',
    toolingLinks: [],
    trafficCessationAlertConfig: sidekiqHelpers.shardTrafficCessationAlertConfig,
  }),

  // Special per-worker recording rules
  extraRecordingRulesPerBurnRate: [
    // Adds per-work queuing/execution apdex, plus error rates etc
    // across multiple burn rates
    perWorkerRecordingRules,
  ],
  capacityPlanning+: {
    components: [
      {
        name: 'rails_db_connection_pool',
        parameters: {
          ignore_outliers: [
            {
              start: '2021-01-01',
              end: '2023-04-10',
            },
          ],
        },
      },
    ],
  },
})
