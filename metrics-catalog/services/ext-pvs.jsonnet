local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local baseSelector = { type: 'ext-pvs' };

metricsCatalog.serviceDefinition(
  // Default Runway SLIs
  runwayArchetype(
    type='ext-pvs',
    team='anti-abuse',
    apdexScore=0.999,
    errorRatio=0.999,
    apdexSatisfiedThreshold='4052.650622296292',
    trafficCessationAlertConfig=false,
    customToolingLinks=[],
  )
)
