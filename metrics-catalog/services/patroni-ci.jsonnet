local patroniHelpers = import './lib/patroni-helpers.libsonnet';

patroniHelpers.serviceDefinition(
  type='patroni-ci',
  serviceDependencies={
    patroni: true,
  },
)
