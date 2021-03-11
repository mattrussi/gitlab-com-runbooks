local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'patroni',
  tier: 'db',
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
  },
  // Use recordingRuleMetrics to specify a set of metrics with known high
  // cardinality. The metrics catalog will generate recording rules with
  // the appropriate aggregations based on this set.
  // Use sparingly, and don't overuse.
  recordingRuleMetrics: [
    'gitlab_sql_duration_seconds_bucket',
    'gitlab_sql_primary_duration_seconds_bucket',
    'gitlab_sql_replica_duration_seconds_bucket',
  ],
  serviceLevelIndicators: {
    // We don't have latency histograms for patroni but for now we will
    // use the rails controller SQL latencies as an indirect proxy.
    rails_sql: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
      description: |||
        Deprecrated: replaced by `rails_primary_sql` and `rails_replica_sql`.

        Represents all SQL transactions issued through ActiveRecord from the Rails monolith. Durations
        can be impacted by various conditions other than Patroni, including client pool saturation, pgbouncer saturation,
        Ruby thread contention and network conditions.
      |||,

      staticLabels: {
        stage: 'main',
      },

      apdex: histogramApdex(
        histogram='gitlab_sql_duration_seconds_bucket',
        selector={},
        satisfiedThreshold=0.05,
        toleratedThreshold=0.1
      ),

      requestRate: rateMetric(
        counter='gitlab_sql_duration_seconds_bucket',
        selector={ le: '+Inf' },
      ),

      significantLabels: [],
    },

    // We don't have latency histograms for patroni but for now we will
    // use the rails controller SQL latencies as an indirect proxy.
    //
    // This is intended to be a replacement for `rails_sql`
    rails_primary_sql: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
      description: |||
        Represents all SQL transactions issued through ActiveRecord from the Rails monolith (currently web, api, websockets, but not sidekiq) to the Postgres primary.
        Durations can be impacted by various conditions other than Patroni, including client pool saturation, pgbouncer saturation,
        Ruby thread contention and network conditions.
      |||,

      staticLabels: {
        stage: 'main',
      },

      apdex: histogramApdex(
        histogram='gitlab_sql_primary_duration_seconds_bucket',
        selector={},
        satisfiedThreshold=0.05,
        toleratedThreshold=0.1
      ),

      requestRate: rateMetric(
        counter='gitlab_sql_primary_duration_seconds_bucket',
        selector={ le: '+Inf' },
      ),

      significantLabels: ['feature_category'],
    },

    // We don't have latency histograms for patroni but for now we will
    // use the rails controller SQL latencies as an indirect proxy.
    //
    // This is intended to be a replacement for `rails_sql`
    rails_replica_sql: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
      description: |||
        Represents all SQL transactions issued through ActiveRecord from the Rails monolith (currently web, api, websockets, but not sidekiq) to Postgres replicas.
        Durations can be impacted by various conditions other than Patroni, including client pool saturation, pgbouncer saturation,
        Ruby thread contention and network conditions.
      |||,

      staticLabels: {
        stage: 'main',
      },

      apdex: histogramApdex(
        histogram='gitlab_sql_primary_duration_seconds_bucket',
        selector={},
        satisfiedThreshold=0.05,
        toleratedThreshold=0.1
      ),

      requestRate: rateMetric(
        counter='gitlab_sql_primary_duration_seconds_bucket',
        selector={ le: '+Inf' },
      ),

      significantLabels: ['feature_category'],
    },

    transactions_primary: {
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
          selector='type="patroni", tier="db"',
          instanceFilter='(pg_replication_is_replica == 0)'
        ),
        rateMetric(
          counter='pg_stat_database_xact_rollback',
          selector='type="patroni", tier="db"',
          instanceFilter='(pg_replication_is_replica == 0)'
        ),
      ]),

      errorRate: rateMetric(
        counter='pg_stat_database_xact_rollback',
        selector='type="patroni", tier="db"',
        instanceFilter='(pg_replication_is_replica == 0)'
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.kibana(title='Postgres', index='postgres', type='patroni', tag='postgres.postgres_csv'),
      ],
    },

    transactions_replica: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
      description: |||
        Represents all SQL transactions issued to replica Postgres instances, in aggregate.
        Errors represent transaction rollbacks.
      |||,

      requestRate: combined([
        rateMetric(
          counter='pg_stat_database_xact_commit',
          selector='type="patroni", tier="db"',
          instanceFilter='(pg_replication_is_replica == 1)'
        ),
        rateMetric(
          counter='pg_stat_database_xact_rollback',
          selector='type="patroni", tier="db"',
          instanceFilter='(pg_replication_is_replica == 1)'
        ),
      ]),

      errorRate: rateMetric(
        counter='pg_stat_database_xact_rollback',
        selector='type="patroni", tier="db"',
        instanceFilter='(pg_replication_is_replica == 1)'
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.kibana(title='Postgres', index='postgres', type='patroni', tag='postgres.postgres_csv'),
      ],
    },

    // Records the operations rate for the pgbouncer instances running on the patroni nodes
    pgbouncer: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
      description: |||
        All transactions destined for the Postgres secondary instances are routed through the pgbouncer instances
        running on the patroni nodes themselves. This SLI models those transactions in aggregate.
      |||,

      // The same query, with different labels is also used on the patroni nodes pgbouncer instances
      requestRate: combined([
        rateMetric(
          counter='pgbouncer_stats_sql_transactions_pooled_total',
          selector='type="patroni", tier="db"'
        ),
        rateMetric(
          counter='pgbouncer_stats_queries_pooled_total',
          selector='type="patroni", tier="db"'
        ),
      ]),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.kibana(title='pgbouncer', index='postgres_pgbouncer', type='patroni', tag='postgres.pgbouncer'),
      ],
    },
  },
})
