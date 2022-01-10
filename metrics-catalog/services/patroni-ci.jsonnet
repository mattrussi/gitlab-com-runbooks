local patroniHelpers = import './lib/patroni-helpers.libsonnet';
local patroniArchetype = import 'service-archetypes/patroni-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  patroniArchetype(
    type='patroni-ci',
    serviceDependencies={
      patroni: true,
    },

    extraTags=[],
  )
  + patroniHelpers.gitlabcomObservabilityToolingForPatroni('patroni-ci')
)
