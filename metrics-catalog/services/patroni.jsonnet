local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local histogramApdex = metricsCatalog.histogramApdex;
local patroniHelpers = import './lib/patroni-helpers.libsonnet';

patroniHelpers.serviceDefinition(
  'patroni',
  {
    // Sidekiq has a distinct usage profile; this is used to select 'the others' which
    // are more interactive and thus require lower thresholds
    // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1059
    local railsBaseSelector = {
      type: { ne: 'sidekiq' },
    },

    // We don't have latency histograms for patroni but for now we will
    // use the rails SQL latencies as an indirect proxy.
    rails_primary_sql: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
      upscaleLongerBurnRates: true,
      description: |||
        Represents all SQL transactions issued through ActiveRecord from the Rails monolith (web, api, websockets, but not sidekiq) to the Postgres primary.
        Durations can be impacted by various conditions other than Patroni, including client pool saturation, pgbouncer saturation,
        Ruby thread contention and network conditions.
      |||,

      apdex: histogramApdex(
        histogram='gitlab_sql_primary_duration_seconds_bucket',
        selector=railsBaseSelector,
        satisfiedThreshold=0.05,
        toleratedThreshold=0.1
      ),

      requestRate: rateMetric(
        counter='gitlab_sql_primary_duration_seconds_bucket',
        selector=railsBaseSelector { le: '+Inf' },
      ),

      significantLabels: ['feature_category'],
    },

    rails_replica_sql: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
      upscaleLongerBurnRates: true,
      description: |||
        Represents all SQL transactions issued through ActiveRecord from the Rails monolith (web, api, websockets, but not sidekiq) to Postgres replicas.
        Durations can be impacted by various conditions other than Patroni, including client pool saturation, pgbouncer saturation,
        Ruby thread contention and network conditions.
      |||,

      apdex: histogramApdex(
        histogram='gitlab_sql_replica_duration_seconds_bucket',
        selector=railsBaseSelector,
        satisfiedThreshold=0.05,
        toleratedThreshold=0.1
      ),

      requestRate: rateMetric(
        counter='gitlab_sql_replica_duration_seconds_bucket',
        selector=railsBaseSelector { le: '+Inf' },
      ),

      significantLabels: ['feature_category'],
    },
  },
)
