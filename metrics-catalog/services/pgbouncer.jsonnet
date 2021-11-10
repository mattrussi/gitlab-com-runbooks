local pgbouncerArchetype = import 'service-archetypes/pgbouncer-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  pgbouncerArchetype(
    type='pgbouncer',
    extraTags=[
      'pgbouncer_async_primary',
    ],
  )
  {
    serviceDependencies: {
      patroni: true,
    },
  }
)
