local patroniArchetype = import 'service-archetypes/patroni-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

function(
  type,
  extraTags=[],
  additionalServiceLevelIndicators={},
  serviceDependencies={},
)
  patroniArchetype(type, extraTags, additionalServiceLevelIndicators, serviceDependencies)
  {
    local db_config_name = if type == 'patroni' then 'main' else std.lstripChars(type, 'patroni-'),
    serviceLevelIndicators+: {
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
        upscaleLongerBurnRates: true,
        description: |||
          Represents all SQL transactions issued through ActiveRecord from the Rails monolith (web, api, websockets, but not sidekiq) to the Postgres primary.
          Durations can be impacted by various conditions other than Patroni, including client pool saturation, pgbouncer saturation,
          Ruby thread contention and network conditions.
        |||,

        apdex: histogramApdex(
          histogram='gitlab_sql_primary_duration_seconds_bucket',
          selector=railsBaseSelector { db_config_name: db_config_name },
          satisfiedThreshold=0.05,
          toleratedThreshold=0.1
        ),

        requestRate: rateMetric(
          counter='gitlab_sql_primary_duration_seconds_bucket',
          selector=railsBaseSelector { le: '+Inf', db_config_name: db_config_name },
        ),

        significantLabels: ['feature_category'],
      },

      rails_replica_sql: {
        userImpacting: true,
        featureCategory: 'not_owned',
        upscaleLongerBurnRates: true,
        description: |||
          Represents all SQL transactions issued through ActiveRecord from the Rails monolith (web, api, websockets, but not sidekiq) to Postgres replicas.
          Durations can be impacted by various conditions other than Patroni, including client pool saturation, pgbouncer saturation,
          Ruby thread contention and network conditions.
        |||,

        apdex: histogramApdex(
          histogram='gitlab_sql_replica_duration_seconds_bucket',
          selector=railsBaseSelector { db_config_name: db_config_name + '_replica' },
          satisfiedThreshold=0.05,
          toleratedThreshold=0.1
        ),

        requestRate: rateMetric(
          counter='gitlab_sql_replica_duration_seconds_bucket',
          selector=railsBaseSelector { le: '+Inf', db_config_name: db_config_name + '_replica' },
        ),

        significantLabels: ['feature_category'],
      },
    },
  }
