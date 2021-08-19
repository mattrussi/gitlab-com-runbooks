local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local serviceDefinition(
  type='pgbouncer'
      ) =
  metricsCatalog.serviceDefinition({
    type: type,
    tier: 'db',
    // pgbouncer doesn't have a `cny` stage
    serviceIsStageless: true,
    serviceDependencies: {
      patroni: true,
    },
    serviceLevelIndicators: {
      local baseSelector = {
        type: type,
        tier: 'db',
      },
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
            selector=baseSelector
          ),
          rateMetric(
            counter='pgbouncer_stats_queries_pooled_total',
            selector=baseSelector
          ),
        ]),

        errorRate: rateMetric(
          counter='pgbouncer_pooler_errors_total',
          selector=baseSelector,
        ),

        significantLabels: ['fqdn', 'error'],

        toolingLinks: [
          toolingLinks.kibana(title='pgbouncer', index='postgres_pgbouncer', type='pgbouncer', tag='postgres.pgbouncer'),
        ],
      },
    },
  });

{
  serviceDefinition:: serviceDefinition,
}
