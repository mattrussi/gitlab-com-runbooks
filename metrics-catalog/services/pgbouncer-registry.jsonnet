local pgbouncerArchetype = import 'service-archetypes/pgbouncer-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  pgbouncerArchetype(
    type='pgbouncer-registry',
  )
  {
    serviceDependencies: {
      'patroni-registry': true,
    },
  }
)
