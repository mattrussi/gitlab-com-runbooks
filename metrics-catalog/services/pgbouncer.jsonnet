local pgbouncerHelpers = import './lib/pgbouncer-helpers.libsonnet';

pgbouncerHelpers.serviceDefinition(
  type='pgbouncer',
  extraTags=['pgbouncer_async_primary'],
)
