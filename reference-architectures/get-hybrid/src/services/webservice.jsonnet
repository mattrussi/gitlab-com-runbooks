local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'webservice',
  tier: 'app',

  tags: ['golang'],

  monitoringThresholds: {
    apdexScore: 0.998,
    errorRatio: 0.9999,
  },

  otherThresholds: {},
  serviceDependencies: {},
  // recordingRuleMetrics: [
  //   'http_requests_total',
  // ],
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  regional: false,
  kubeResources: {
    web: {
      kind: 'Deployment',
      containers: [
        'gitlab-workhorse',
        'webservice',
      ],
    },
  },

  serviceLevelIndicators: {
    puma: {
      userImpacting: true,
      description: |||
        Aggregation of most web requests that pass through the puma to the GitLab rails monolith.
        Healthchecks are excluded.
      |||,

      local baseSelector = { job: 'gitlab-rails' },
      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=baseSelector,
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=baseSelector,
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=baseSelector { status: { re: '5..' } }
      ),

      significantLabels: [],

      toolingLinks: [],
    },
  },

  extraRecordingRulesPerBurnRate: [],
})
