local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local gaugeMetric = metricsCatalog.gaugeMetric;

metricsCatalog.serviceDefinition({
  type: 'cloud-sql',
  tier: 'db',

  tags: ['cloud-sql'],

  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.9999,
  },
  regional: false,

  provisioning: {
    vms: false,
    kubernetes: false,
  },

  serviceLevelIndicators: {
    cloudsql_transactions: {
      userImpacting: true,
      description: |||
        This SLI represents SQL transactions in Cloud SQL databases.
      |||,

      local baseSelector = {
        database: { nre: 'postgres|template[0-9]+|default|cloudsqladmin' },
      },

      requestRate: gaugeMetric(
        gauge='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_transaction_count',
        selector=baseSelector
      ),

      errorRate: gaugeMetric(
        gauge='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_transaction_count',
        selector=baseSelector {
          transaction_type: 'rollback',
        }
      ),

      significantLabels: ['database_id'],
    },
  },
})
