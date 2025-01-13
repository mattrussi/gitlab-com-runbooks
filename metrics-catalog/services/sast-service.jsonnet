local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local sliLibrary = import 'gitlab-slis/library.libsonnet';

metricsCatalog.serviceDefinition(
  runwayArchetype(
    type='sast-service',
    team='static_analysis',
    regional=true,
    featureCategory='static_application_security_testing',
    tags=['golang'],
    userImpacting=false,
    trafficCessationAlertConfig=false,
  )
)
