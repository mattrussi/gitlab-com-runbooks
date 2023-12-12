local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'frontend',
  tier: 'lb',
  tags: ['haproxy', 'gateway'],
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.9999,
  },
  serviceDependencies: {
    git: true,
    api: true,
    web: true,
    registry: true,
  },
  serviceLevelIndicators: {
    // We want to keep track of the errors that are our faults (backend failures) and not the client faults.
    // For this reason, we use haproxy_backend_* metrics (not haproxy_frontend_* ones)

    mainHttpsServices: {
      // HAProxy frontends and backends are proxy to actual services.
      // These services are monitored separately as user-impacting services.
      userImpacting: false,

      significantLabels: ['fqdn'],
      staticLabels: {
        stage: 'main',
      },

      requestRate: rateMetric(
        counter='haproxy_backend_http_requests_total',
        selector='type="frontend", backend!~"ssh|api_rate_limit|canary_.*"'
      ),

      responseRate: rateMetric(
        counter='haproxy_backend_http_responses_total',
        selector='type="frontend", backend!~"ssh|api_rate_limit|canary_.*"'
      ),

      errorRate: rateMetric(
        counter='haproxy_backend_response_errors_total',
        selector='type="frontend", backend!~"ssh|api_rate_limit|canary_.*"'
      ),

      toolingLinks: [
        toolingLinks.bigquery(
          title='Top main stage HTTPS clients by the number of requests (10m)',
          savedQuery='805818759045:b616edd259de48e29e6e3c747f70a26b',
        ),
      ],
    },

    cnyHttpsServices: {
      // HAProxy frontends and backends are proxy to actual services.
      // These services are monitored separately as user-impacting services.
      userImpacting: false,

      significantLabels: ['fqdn'],
      staticLabels: {
        stage: 'cny',
      },

      requestRate: rateMetric(
        counter='haproxy_backend_http_requests_total',
        selector='type="frontend", backend=~"canary_.*"'
      ),

      responseRate: rateMetric(
        counter='haproxy_backend_http_responses_total',
        selector='type="frontend", backend=~"canary_.*"'
      ),

      errorRate: rateMetric(
        counter='haproxy_backend_response_errors_total',
        selector='type="frontend", backend=~"canary_.*"'
      ),

      toolingLinks: [
        toolingLinks.bigquery(
          title='Top canary stage HTTPS clients by the number of requests (10m)',
          savedQuery='805818759045:8c5c04d0471442449fb38cb9505fe8c7',
        ),
      ],
    },

    sshServices: {
      // HAProxy frontends and backends are proxy to actual services.
      // These services are monitored separately as user-impacting services.
      userImpacting: false,

      significantLabels: ['fqdn'],

      monitoringThresholds+: {
        apdexScore: 0.99,
        errorRatio: 0.999,
      },

      requestRate: rateMetric(
        counter='haproxy_backend_http_requests_total',
        selector='type="frontend", backend="ssh"'
      ),

      responseRate: rateMetric(
        counter='haproxy_backend_http_responses_total',
        selector='type="frontend", backend="ssh"'
      ),

      errorRate: rateMetric(
        counter='haproxy_backend_response_errors_total',
        selector='type="frontend", backend="ssh"'
      ),

      toolingLinks: [
        toolingLinks.bigquery(
          title='Top SSH clients by the number of requests (10m)',
          savedQuery='805818759045:d72111fcd69b4b5bb97f9b33b80f9edb',
        ),
      ],
    },
  },

  skippedMaturityCriteria: {
    'Structured logs available in Kibana': 'Logs from HAProxy are available in BigQuery, and not ingested to ElasticSearch due to volume.',
  },
})
