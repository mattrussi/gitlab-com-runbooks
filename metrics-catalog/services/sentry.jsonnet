local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;
local maturityLevels = import 'service-maturity/levels.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'sentry',
  tier: 'inf',
  monitoringThresholds: {
    apdexScore: 0.99,
    // Setting the Error SLO at 99% because we see high transaction rollback rates
    // TODO: investigate
    errorRatio: 0.99,
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

    pg_transactions: {
      userImpacting: false,
      serviceAggregation: false,
      featureCategory: 'not_owned',
      team: 'sre_observability',
      description: |||
        Represents all SQL transactions issued to the sentry Postgres instance.
        Errors represent transaction rollbacks.
      |||,

      local baseSelector = { type: 'sentry', job: 'postgres', datname: 'sentry' },

      requestRate: combined([
        rateMetric(
          counter='pg_stat_database_xact_commit',
          selector=baseSelector,
        ),
        rateMetric(
          counter='pg_stat_database_xact_rollback',
          selector=baseSelector,
        ),
      ]),

      errorRate: rateMetric(
        counter='pg_stat_database_xact_rollback',
        selector=baseSelector,
      ),

      significantLabels: [],
      toolingLinks: [],
    },

  },
  skippedMaturityCriteria: maturityLevels.getCriterias([
    'Service exists in the dependency graph',
  ]),
})
