local gitalyHelper = import 'service-archetypes/helpers/gitaly.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local combined = metricsCatalog.combined;
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
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

  kubeConfig: {
    local kubeSelector = baseSelector,
    labelSelectors: kubeLabelSelectors(
      podSelector=kubeSelector,
      hpaSelector=kubeSelector,
      ingressSelector=kubeSelector,
      deploymentSelector=kubeSelector
    ),
  },
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

  serviceLevelIndicators: {
    // webservice
    puma: {
      userImpacting: true,
      team: 'reliability_foundations',
      severity: 's3',  // don't page the EOC yet
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
        toolingLinks.kibana(title='Puma', index='rails', type='default', slowRequestSeconds=10),
      ],
    },

    workhorse: {
      userImpacting: true,
      team: 'reliability_foundations',
      severity: 's3',  // don't page the EOC yet
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
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='default', slowRequestSeconds=10),
      ],
    },

    // gitaly
    goserver: {
      userImpacting: true,
      team: 'reliability_foundations',
      severity: 's3',  // don't page the EOC yet
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
        toolingLinks.kibana(title='Gitaly', index='gitaly', slowRequestSeconds=1),
      ],
    },

    // Still to come:
    //
    // - sidekiq
    // - registry
    // - git (https/ssh)
    // - ...
  },
})
