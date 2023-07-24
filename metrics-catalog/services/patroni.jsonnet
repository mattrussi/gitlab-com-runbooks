local patroniHelpers = import './lib/patroni-helpers.libsonnet';
local patroniRailsArchetype = import 'service-archetypes/patroni-rails-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  patroniRailsArchetype(
    'patroni',
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
    skippedMaturityCriteria: {
      'Developer guides exist in developer documentation': 'patroni is an infrastructure component, developers do not interact with it',
    },
  }
  + patroniHelpers.gitlabcomObservabilityToolingForPatroni('patroni')
  +
  {
    capacityPlanning: {
      components: [
        {
          name: 'memory',
          parameters: {
            changepoints: [
              '2023-04-26',  // https://gitlab.com/gitlab-com/gl-infra/capacity-planning/-/issues/1026#note_1404708663
              '2023-04-28',
            ],

          },
        },
        {
          name: 'pg_int4_id',
          events: [
            {
              date: '2023-03-20',
              name: 'Migration to int8 column to address int4 capacity saturation',
            },
            {
              date: '2023-04-06',
              name: 'Migration to int8 column to address int4 capacity saturation',
            },
            {
              date: '2023-06-15',
              name: 'Migration to int8 column to address int4 capacity saturation',
            },
          ],
        },
      ],
    },
  }
)
