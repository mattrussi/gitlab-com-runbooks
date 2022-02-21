local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;

metricsCatalog.serviceDefinition({
  type: 'pages',
  tier: 'lb',
  serviceIsStageless: true,  // pages does not have a cny stage
  monitoringThresholds: {
    errorRatio: 0.9999,
  },
  serviceDependencies: {
    'web-pages': true,
  },
  /*
   * No need to have operation rate alerting for both pages and web-pages
   * so disabling it for this service, and keeping the anomaly detection
   * at the web-pages level
   */
  disableOpsRatePrediction: true,
  serviceLevelIndicators: {
    loadbalancer: {
      userImpacting: false,  // This HAProxy backend is also monitored in `web-pages`, so make it non userImpacting
      featureCategory: 'pages',
      description: |||
        This SLI models requests passing through the loadbalancer in front of the pages service.
        5xx requests for unencrypted HTTP traffic, and connection errors (not 5xx requests) for
        HTTPS traffic are considered to be errors. The loadbalancer is unable to determine the
        status code of HTTPS traffic as it passes through the loadbalancer encrypted.
      |||,

      requestRate: rateMetric(
        counter='haproxy_server_sessions_total',
        selector={ type: 'pages', backend: { re: 'pages_https|pages_http' } }
      ),

      errorRate: combined([
        rateMetric(
          counter='haproxy_backend_http_responses_total',
          selector={ type: 'pages', job: 'haproxy', code: '5xx' }
        ),
        rateMetric(
          counter='haproxy_server_connection_errors_total',
          selector={ type: 'pages', job: 'haproxy' }
        ),
      ]),

      significantLabels: [],
    },
  },
})
