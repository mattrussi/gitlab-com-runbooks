local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';
local sliLibrary = import 'gitlab-slis/library.libsonnet';
local serviceLevelIndicatorDefinition = import 'servicemetrics/service_level_indicator_definition.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

local railsSelector = { job: 'gitlab-rails', type: 'ai-assisted' };

metricsCatalog.serviceDefinition({
  type: 'ai-assisted',
  tier: 'sv',

  tags: ['golang', 'rails', 'puma'],

  contractualThresholds: {
    apdexRatio: 0.9,
    errorRatio: 0.005,
  },
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.999,
  },
  serviceDependencies: {
    api: true,
    'ai-gateway': true,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  kubeResources: {
    'ai-assisted': {
      kind: 'Deployment',
      containers: [
        'gitlab-workhorse',
        'webservice',
      ],
    },
  },
  serviceLevelIndicators: {
    workhorse: {
      userImpacting: false,
      serviceAggregation: false,
      featureCategory: 'not_owned',
      team: 'workhorse',
      description: |||
        Aggregation of most web requests that pass through workhorse, monitored via the HTTP interface.
        Excludes health, readiness and liveness requests. Some known slow requests, such as HTTP uploads,
        are excluded from the apdex score.
      |||,

      local workhorseSelector = {
        job: { re: 'gitlab-workhorse-api|gitlab-workhorse' },
        type: 'ai-assisted',
      },
      local healthCheckSelector = {
        route: { ne: ['^/-/health$', '^/-/(readiness|liveness)$'] },
      },

      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        selector=workhorseSelector + healthCheckSelector,
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=workhorseSelector
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=workhorseSelector + healthCheckSelector + {
          code: { re: '^5.*' },
        }
      ),

      significantLabels: ['region', 'method', 'route'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-api'),
        toolingLinks.sentry(projectId=15),
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='ai-assisted', slowRequestSeconds=10),
      ],

      severity: 's3',  // Don't page SREs for this SLI
    },
  } + sliLibrary.get('rails_request').generateServiceLevelIndicator(railsSelector, {
    monitoringThresholds+: {
      apdexScore: 0.99,
    },

    toolingLinks: [
      toolingLinks.kibana(title='Rails', index='rails'),
    ],
    severity: 's3',  // Don't page SREs for this SLI
  }),
})
