local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'tracing',
  tier: 'inf',
  monitoringThresholds: {
    // apdexScore: 0.999,
    errorRatio: 0.999,
  },
  components: {
    jaeger_agent: {
      apdex: histogramApdex(
        histogram='jaeger_rpc_request_latency_bucket',
        selector='',
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='jaeger_rpc_http_requests_total',
        selector='',
      ),

      errorRate: rateMetric(
        counter='jaeger_rpc_http_requests_total',
        selector={ status_code: { re: '4xx|5xx' } }
      ),

      significantLabels: ['fqdn'],
    },

    jaeger_collector: {
      apdex: histogramApdex(
        histogram='jaeger_collector_save_latency_bucket',
        selector='',
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='jaeger_collector_spans_received_total',
        selector='',
      ),

      errorRate: rateMetric(
        counter='jaeger_collector_spans_dropped_total',
        selector=''
      ),

      significantLabels: ['fqdn', 'pod'],
    },

    jaeger_query: {
      apdex: histogramApdex(
        histogram='jaeger_query_latency_bucket',
        selector='',
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='jaeger_query_requests_total',
        selector='',
      ),

      errorRate: rateMetric(
        counter='jaeger_query_requests_total',
        selector='result="err"'
      ),

      significantLabels: ['fqdn', 'pod'],
    },
  },
})
