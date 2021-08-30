local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'woodhouse',
  tier: 'sv',
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  kubeResources: {
    woodhouse: {
      kind: 'Deployment',
      containers: [
        'woodhouse',
      ],
    },
  },
  serviceLevelIndicators: {
    http: {
      userImpacting: false,
      feature_category: 'not_owned',
      team: 'sre_observability',
      ignoreTrafficCessation: true,

      description: |||
        HTTP requests handled by woodhouse.
      |||,

      local selector = { job: 'woodhouse', route: { ne: '/ready' } },
      apdex: histogramApdex(
        histogram='woodhouse_http_request_duration_seconds_bucket',
        selector=selector,
        satisfiedThreshold=1,
      ),
      requestRate: rateMetric(
        counter='woodhouse_http_requests_total',
        selector=selector,
      ),
      errorRate: rateMetric(
        // Slack handlers return HTTP 200 even when there is an error, because
        // unfortunately that is how the Slack API works, and is the only way to
        // show errors to callers. Therefore, woodhouse exposes a separate
        // metric for this rather than relying on 5xx.
        counter='woodhouse_http_requests_errors_total',
        selector=selector,
      ),
      significantLabels: [],

      toolingLinks: [],  // TODO
    },

    async_jobs: {
      userImpacting: false,
      feature_category: 'not_owned',
      team: 'sre_observability',
      ignoreTrafficCessation: true,

      description: |||
        Async jobs performed by woodhouse.
      |||,

      local selector = { job: 'woodhouse' },
      apdex: histogramApdex(
        histogram='woodhouse_async_job_duration_seconds_bucket',
        selector=selector,
        satisfiedThreshold=10,
      ),
      requestRate: rateMetric(
        counter='woodhouse_async_jobs_total',
        selector=selector,
      ),
      errorRate: rateMetric(
        counter='woodhouse_async_jobs_total',
        selector=selector { status: 'error' },
      ),
      significantLabels: ['job_name'],

      toolingLinks: [],  // TODO
    },
  },
})
