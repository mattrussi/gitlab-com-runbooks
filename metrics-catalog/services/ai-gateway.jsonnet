local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition(
  runwayArchetype(
    type='ai_gateway',
    team='ai_assisted',
    runwayServiceID='model-gateway-n2bsxg',
  )
)
