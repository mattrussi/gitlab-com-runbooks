local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  runwayArchetype(
    type='secret_detection_scanner',
    team='secret_detection',
  )
)
