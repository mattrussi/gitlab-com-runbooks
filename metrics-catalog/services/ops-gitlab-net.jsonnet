local registryHelpers = import './lib/registry-helpers.libsonnet';
local gitalyHelper = import 'service-archetypes/helpers/gitaly.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local combined = metricsCatalog.combined;
local successCounterApdex = metricsCatalog.successCounterApdex;
local rateMetric = metricsCatalog.rateMetric;
local histogramApdex = metricsCatalog.histogramApdex;

local baseSelector = { type: 'ops-gitlab-net' };

metricsCatalog.serviceDefinition({
  type: 'ops-gitlab-net',
  tier: 'sv',
  serviceIsStageless: true,

  tags: ['golang', 'rails'],

  monitoringThresholds: {
    apdexScore: 0.998,
    errorRatio: 0.9999,
  },
  otherThresholds: {},
  serviceDependencies: {},

  provisioning: {
    vms: false,
    kubernetes: true,
  },
  regional: false,

  kubeConfig: {},
  kubeResources: {
    webservice: {
      kind: 'Deployment',
      containers: [
        'gitlab-workhorse',
        'webservice',
      ],
    },
    gitaly: {
      kind: 'StatefulSet',
      containers: [
        'gitaly',
      ],
    },
    kas: {
      kind: 'Deployment',
      containers: [
        'kas',
      ],
    },
    registry: {
      kind: 'Deployment',
      containers: [
        'registry',
      ],
    },
    sidekiq: {
      kind: 'Deployment',
      containers: [
        'sidekiq',
      ],
    },
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

  serviceLevelIndicators: {
    local sliCommon = {
      userImpacting: true,
      team: 'reliability_foundations',
      severity: 's3',  // don't page the EOC yet
    },

    // webservice
    puma: sliCommon {
      description: |||
        Aggregation of most web requests that pass through the puma to the GitLab rails monolith.
        Healthchecks are excluded.
      |||,

      local railsSelector = baseSelector { job: 'gitlab-rails' },

      apdex: successCounterApdex(
        successRateMetric='gitlab_sli_rails_request_apdex_success_total',
        operationRateMetric='gitlab_sli_rails_request_apdex_total',
        selector=railsSelector,
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=railsSelector,
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=railsSelector { status: { re: '5..' } }
      ),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.kibana(title='Puma', index='rails_ops', slowRequestSeconds=10, includeMatchersForPrometheusSelector=false),
      ],
    },

    workhorse: sliCommon {
      featureCategory: 'not_owned',
      description: |||
        Aggregation of most web requests that pass through workhorse, monitored via the HTTP interface.
        Excludes health, readiness and liveness requests. Some known slow requests, such as HTTP uploads,
        are excluded from the apdex score.
      |||,

      local workhorseWebSelector = baseSelector { job: 'gitlab-workhorse' },

      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        selector=workhorseWebSelector {
          route: {
            ne: [
              '^/([^/]+/){1,}[^/]+/uploads\\\\z',
              '^/-/health$',
              '^/-/(readiness|liveness)$',
              '^/([^/]+/){1,}[^/]+\\\\.git/git-receive-pack\\\\z',
              '^/([^/]+/){1,}[^/]+\\\\.git/git-upload-pack\\\\z',
              '^/([^/]+/){1,}[^/]+\\\\.git/info/refs\\\\z',
              '^/([^/]+/){1,}[^/]+\\\\.git/gitlab-lfs/objects/([0-9a-f]{64})/([0-9]+)\\\\z',
            ],
          },
        },
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=workhorseWebSelector,
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=workhorseWebSelector {
          code: { re: '^5.*' },
          route: { ne: ['^/-/health$', '^/-/(readiness|liveness)$'] },
        },
      ),

      significantLabels: ['route'],

      toolingLinks: [
        toolingLinks.kibana(title='Workhorse', index='workhorse_ops', slowRequestSeconds=10, includeMatchersForPrometheusSelector=false),
      ],
    },

    // gitaly
    goserver: sliCommon {
      featureCategory: 'gitaly',
      description: |||
        This SLI monitors all Gitaly GRPC requests in aggregate, excluding the OperationService.
        GRPC failures which are considered to be the "server's fault" are counted as errors.
        The apdex score is based on a subset of GRPC methods which are expected to be fast.
      |||,

      local gitalyBaseSelector = baseSelector { job: 'gitaly' },

      local apdexSelector = gitalyBaseSelector {
        grpc_service: { ne: ['gitaly.OperationService'] },
      },
      local mainApdexSelector = apdexSelector {
        grpc_method: { noneOf: gitalyHelper.gitalyApdexIgnoredMethods + gitalyHelper.gitalyApdexSlowMethods },
      },
      local slowMethodApdexSelector = apdexSelector {
        grpc_method: { oneOf: gitalyHelper.gitalyApdexSlowMethods },
      },
      local operationServiceApdexSelector = gitalyBaseSelector {
        grpc_service: ['gitaly.OperationService'],
      },

      apdex: combined(
        [
          gitalyHelper.grpcServiceApdex(mainApdexSelector),
          gitalyHelper.grpcServiceApdex(slowMethodApdexSelector, satisfiedThreshold=10, toleratedThreshold=30),
          gitalyHelper.grpcServiceApdex(operationServiceApdexSelector, satisfiedThreshold=10, toleratedThreshold=30),
        ]
      ),

      requestRate: rateMetric(
        counter='gitaly_service_client_requests_total',
        selector=gitalyBaseSelector
      ),

      errorRate: gitalyHelper.gitalyGRPCErrorRate(gitalyBaseSelector),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.kibana(title='Gitaly', index='gitaly_ops', slowRequestSeconds=1, includeMatchersForPrometheusSelector=false),
      ],
    },

    local sidekiqBaseSelector = baseSelector { job: 'sidekiq' },

    // sidekiq
    shard_default: sliCommon {
      upscaleLongerBurnRates: true,

      description: |||
        All Sidekiq jobs
      |||,

      local highUrgencySelector = sidekiqBaseSelector { urgency: 'high' },
      local lowUrgencySelector = sidekiqBaseSelector { urgency: 'low' },
      local throttledUrgencySelector = sidekiqBaseSelector { urgency: 'throttled' },

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
      },

      apdex: combined(
        [
          histogramApdex(
            histogram='sidekiq_jobs_completion_seconds_bucket',
            selector=highUrgencySelector,
            satisfiedThreshold=slos.urgent.executionDurationSeconds,
          ),
          histogramApdex(
            histogram='sidekiq_jobs_queue_duration_seconds_bucket',
            selector=highUrgencySelector,
            satisfiedThreshold=slos.urgent.queueingDurationSeconds,
          ),
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
        ]
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector=sidekiqBaseSelector { le: '+Inf' },
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=sidekiqBaseSelector,
      ),

      // Note: these labels will also be included in the
      // intermediate recording rules specified in the
      // `recordingRuleMetrics` stanza above
      significantLabels: ['feature_category', 'queue', 'urgency', 'worker'],

      // Consider adding useful links for the environment in the future.
      toolingLinks: [
        toolingLinks.kibana(title='shard_default', index='sidekiq_ops', slowRequestSeconds=slos.lowUrgency.executionDurationSeconds, includeMatchersForPrometheusSelector=false),
      ],
    },

    email_receiver: sliCommon {
      featureCategory: 'not_owned',
      description: |||
        Monitors ratio between all received emails and received emails which
        could not be processed for some reason.
      |||,

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_count',
        selector=sidekiqBaseSelector { worker: { re: 'EmailReceiverWorker|ServiceDeskEmailReceiverWorker' } }
      ),

      errorRate: rateMetric(
        counter='gitlab_transaction_event_email_receiver_error_total',
        selector=sidekiqBaseSelector { 'error': { ne: 'Gitlab::Email::AutoGeneratedEmailError' } }
      ),

      monitoringThresholds+: {
        errorRatio: 0.7,
      },

      significantLabels: ['error'],

      toolingLinks: [
        toolingLinks.kibana(title='Email receiver errors', index='sidekiq_ops', message='Error processing message', includeMatchersForPrometheusSelector=false),
      ],
    },

    // registry
    registry_server: sliCommon {
      description: |||
        Aggregation of all registry HTTP requests.
      |||,

      local registryBaseSelector = baseSelector { job: 'registry' },

      apdex: registryHelpers.mainApdex(registryBaseSelector),

      requestRate: rateMetric(
        counter='registry_http_requests_total',
        selector=registryBaseSelector,
      ),

      errorRate: rateMetric(
        counter='registry_http_requests_total',
        selector=registryBaseSelector { code: { re: '5..' } }
      ),

      significantLabels: ['route', 'method'],

      toolingLinks: [
        toolingLinks.kibana(title='Registry', index='registry_ops', slowRequestSeconds=10, includeMatchersForPrometheusSelector=false),
      ],
    },

    // git over SSH
    gitlab_sshd: sliCommon {
      monitoringThresholds+: {
        errorRatio: 0.999,
      },
      featureCategory: 'source_code_management',
      description: |||
        Monitors Gitlab-sshd, using the connections bucket, and http requests bucket.
      |||,

      local gitlabSshdBaseSelector = baseSelector { job: 'gitlab-shell' },

      apdex: histogramApdex(
        histogram='gitlab_shell_sshd_session_established_duration_seconds_bucket',
        selector=gitlabSshdBaseSelector,
        satisfiedThreshold=1,
        toleratedThreshold=5
      ),

      errorRate: rateMetric(
        counter='gitlab_sli:shell_sshd_sessions:errors_total',
        selector=gitlabSshdBaseSelector
      ),

      requestRate: rateMetric(
        counter='gitlab_sli:shell_sshd_sessions:total',
        selector=gitlabSshdBaseSelector
      ),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.kibana(title='GitLab Shell', index='shell_ops', includeMatchersForPrometheusSelector=false),
      ],
    },
  },

  skippedMaturityCriteria: {
    'Service exists in the dependency graph': 'ops.gitlab.net is a standalone GitLab deployment',
  },
})
