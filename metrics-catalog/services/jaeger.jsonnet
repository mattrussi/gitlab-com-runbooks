local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'jaeger',
  tier: 'inf',
  monitoringThresholds: {
    // apdexScore: 0.999,
    errorRatio: 0.999,
  },
  serviceLevelIndicators: {
    jaeger_agent: {
      apdex: histogramApdex(
        histogram='jaeger_rpc_request_latency_bucket',
        selector='type="jaeger"',
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='jaeger_rpc_http_requests_total',
        selector='type="jaeger"',
      ),

      errorRate: rateMetric(
        counter='jaeger_rpc_http_requests_total',
        selector={
          type: 'jaeger',
          status_code: { re: '4xx|5xx' },
        }
      ),

      significantLabels: ['fqdn'],
    },

    jaeger_collector: {
      apdex: histogramApdex(
        histogram='jaeger_collector_save_latency_bucket',
        selector='type="jaeger"',
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='jaeger_collector_spans_received_total',
        selector='type="jaeger"',
      ),

      errorRate: rateMetric(
        counter='jaeger_collector_spans_dropped_total',
        selector='type="jaeger"'
      ),

      significantLabels: ['fqdn', 'pod'],
    },

    jaeger_query: {
      apdex: histogramApdex(
        histogram='jaeger_query_latency_bucket',
        selector='type="jaeger"',
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='jaeger_query_requests_total',
        selector='type="jaeger"',
      ),

      errorRate: rateMetric(
        counter='jaeger_query_requests_total',
        selector='result="err"'
      ),

      significantLabels: ['fqdn', 'pod'],
    },
  },
})
