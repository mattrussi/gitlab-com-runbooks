local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'sentry',
  tier: 'inf',
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
  },
  /*
   * Our anomaly detection uses normal distributions and the monitoring service
   * is prone to spikes that lead to a non-normal distribution. For that reason,
   * disable ops-rate anomaly detection on this service.
   */
  provisioning: {
    kubernetes: false,
    vms: true,
  },
  serviceLevelIndicators: {

    sentry_events: {
      userImpacting: false,
      featureCategory: 'not_owned',
      team: 'sre_observability',
      description: |||
        Sentry is an application monitoring platform.
         This SLI monitors the sentry API. 5xx responses are considered failures.
      |||,

      local sentryQuerySelector = {
        job: 'statsd_exporter',
        type: 'sentry',
      },

      apdex: histogramApdex(
        histogram='sentry_events_latency_seconds_bucket',
        selector=sentryQuerySelector,
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='sentry_client_api_responses_total',
        selector=sentryQuerySelector,
      ),

      errorRate: rateMetric(
        counter='sentry_client_api_responses_total',
        selector=sentryQuerySelector { status: { re: '^5.*' } },
      ),

      significantLabels: ['api_version', 'status'],

    },
  },
})
