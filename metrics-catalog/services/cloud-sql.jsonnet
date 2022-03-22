local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local gaugeMetric = metricsCatalog.gaugeMetric;
local maturityLevels = import 'service-maturity/levels.libsonnet';

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
      trafficCessationAlertConfig: false,
      description: |||
        This SLI represents SQL transactions in Cloud SQL databases.
      |||,

      local baseSelector = {
        database_id: { nre: '.+:(praefect-db-|grafana-).+' },
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

      toolingLinks: [
        toolingLinks.stackdriverLogs(
          title='Stackdriver Logs: Cloud SQL',
          queryHash={
            'resource.type': 'cloudsql_database',
          },
        ),
      ],
    },
  },
  skippedMaturityCriteria: maturityLevels.skip({
    'Structured logs available in Kibana': 'Cloud SQL is a managed service of GCP. The logs are available in Stackdriver.',
  }),
})
