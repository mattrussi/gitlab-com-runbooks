local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  runwayArchetype(
    type='sast-scanner-service',
    team='static_analysis',
    featureCategory='static_application_security_testing'
  )
)
