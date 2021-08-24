local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;

local selector = { type: 'postgres-archive', tier: 'db' };

metricsCatalog.serviceDefinition({
  type: 'postgres-archive',
  tier: 'db',

  serviceLevelIndicators: {
    transactions: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
      description: |||
        Represents all SQL transactions issued to the primary Postgres instance.
        Errors represent transaction rollbacks.
      |||,

      requestRate: combined([
        rateMetric(
          counter='pg_stat_database_xact_commit',
          selector=selector,
        ),
        rateMetric(
          counter='pg_stat_database_xact_rollback',
          selector=selector,
        ),
      ]),

      errorRate: rateMetric(
        counter='pg_stat_database_xact_rollback',
        selector=selector,
      ),

      significantLabels: [],

      toolingLinks: [
      ],
    },
  },
})
