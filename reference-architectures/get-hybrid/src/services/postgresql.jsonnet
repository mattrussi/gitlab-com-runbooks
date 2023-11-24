local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local combined = metricsCatalog.combined;
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'postgresql',
  tier: 'db',

  tags: [
    'postgresql',
  ],

  monitoringThresholds: {
    apdexScore: 0.5,
    errorRatio: 0.5,
  },
  
  // We leverage <some cloud service provided database> instead of our own infra here.
  provisioning: {
    vms: false,
    kubernetes: false,
  },

  serviceLevelIndicators: {
    transactions: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        Represents all SQL transactions issued to the primary Postgres instance.
        Errors represent transaction rollbacks.
      |||,

      requestRate: combined([
        rateMetric(
          counter='pg_stat_database_xact_commit',
        ),
        rateMetric(
          counter='pg_stat_database_xact_rollback',
        ),
      ]),

      errorRate: rateMetric(
        counter='pg_stat_database_xact_rollback',
      ),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.kibana(title='PostgreSQL', index='postgresql', includeMatchersForPrometheusSelector=false),
      ],
    },
  },
  skippedMaturityCriteria: {
    'Developer guides exist in developer documentation': 'postgressql is an infrastructure component, developers do not interact with it',
  },
})
