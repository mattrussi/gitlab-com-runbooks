local redisArchetype = import 'service-archetypes/runway-redis-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='redis-runway-managed',
    descriptiveName='Redis managed by Runway'
  )
)
