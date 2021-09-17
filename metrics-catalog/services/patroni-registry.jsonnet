local patroniHelpers = import './lib/patroni-helpers.libsonnet';

patroniHelpers.serviceDefinition(
  type='patroni-registry',
  serviceDependencies={
    patroni: true,
  },
)
