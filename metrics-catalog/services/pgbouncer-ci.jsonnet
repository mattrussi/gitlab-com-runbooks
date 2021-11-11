local pgbouncerHelpers = import './lib/pgbouncer-helpers.libsonnet';

pgbouncerHelpers.serviceDefinition(type='pgbouncer-ci')
