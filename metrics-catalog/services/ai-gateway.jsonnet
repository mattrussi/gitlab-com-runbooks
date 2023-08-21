local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition(
  runwayArchetype(
    type='ai_gateway',
    // TODO: Change team to ai_assisted after https://gitlab.com/gitlab-com/gl-infra/readiness/-/issues/81
    team='scalability-runway-core',
    runwayServiceID='model-gateway-n2bsxg',
    apdexSatisfiedThreshold=2048
  )
)
