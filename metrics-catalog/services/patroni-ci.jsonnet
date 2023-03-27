local patroniHelpers = import './lib/patroni-helpers.libsonnet';
local patroniRailsArchetype = import 'service-archetypes/patroni-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;

metricsCatalog.serviceDefinition(
  patroniRailsArchetype(
    type='patroni-ci',
    serviceDependencies={
      patroni: true,
    },

    extraTags=[
      // disk_performance_monitoring requires disk utilisation metrics are currently reporting correctly for
      // HDD volumes, see https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/10248
      // as such, we only record this utilisation metric on IO subset of the fleet for now.
      'disk_performance_monitoring',

      // pgbouncer_async_replica implies that this service is running a pgbouncer for sidekiq clients
      // in front of a postgres replica
      'pgbouncer_async_replica',

      // postgres_fluent_csvlog_monitoring implies that this service is running fluent-csvlog with vacuum parsing.
      // In future, this should be something we can fold into postgres_with_primaries, but not all postgres instances
      // handle this at present.
      'postgres_fluent_csvlog_monitoring',
    ],
  )
  {
    serviceLevelIndicators+: {
      rails_replica_sql+: {
        apdex: histogramApdex(
          histogram='gitlab_sql_replica_duration_seconds_bucket',
          selector={ type: { ne: 'sidekiq' }, db_config_name: 'ci_replica' },
          satisfiedThreshold=0.1,
          toleratedThreshold=0.25
        ),
      },
    },
    skippedMaturityCriteria: {
      'Developer guides exist in developer documentation': 'patroni is an infrastructure component, developers do not interact with it',
    },
  }
  + patroniHelpers.gitlabcomObservabilityToolingForPatroni('patroni-ci')
)
