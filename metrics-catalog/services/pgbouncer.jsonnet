local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'pgbouncer',
  tier: 'db',
  // pgbouncer doesn't have a `cny` stage
  serviceIsStageless: true,
  serviceDependencies: {
    patroni: true,
  },
  serviceLevelIndicators: {
    service: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
      description: |||
        All transactions destined for the Postgres primary instance are routed through the pgbouncer service.
        This SLI models those transactions in aggregate.

        Error rate uses mtail metrics from pgbouncer logs.
      |||,

      // The same query, with different labels is also used on the patroni nodes pgbouncer instances
      requestRate: combined([
        rateMetric(
          counter='pgbouncer_stats_sql_transactions_pooled_total',
          selector='type="pgbouncer", tier="db"'
        ),
        rateMetric(
          counter='pgbouncer_stats_queries_pooled_total',
          selector='type="pgbouncer", tier="db"'
        ),
      ]),

      errorRate: rateMetric(
        counter='pgbouncer_pooler_errors_total',
        selector='type="pgbouncer", tier="db"',
      ),

      significantLabels: ['fqdn', 'error'],

      toolingLinks: [
        toolingLinks.kibana(title='pgbouncer', index='postgres_pgbouncer', type='pgbouncer', tag='postgres.pgbouncer'),
      ],
    },
  },
})
