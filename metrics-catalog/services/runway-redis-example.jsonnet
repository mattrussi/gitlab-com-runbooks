local redisArchetype = import 'service-archetypes/runway-redis-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  redisArchetype(
    type='example-basic-redis',
    descriptiveName='Example Redis managed by Runway'
  )
)
