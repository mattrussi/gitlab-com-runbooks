local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  runwayArchetype(
    type='topology-rest',
    team='tenant_scale',
    regional=true,
    apdexSatisfiedThreshold='20',
    apdexScore=0.9995,
    errorRatio=0.9995,
    severity='s3'
  )
)
