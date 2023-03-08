local periodicQuery = import './periodic-query.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local defaultSelector = {
  env: 'gprd',
  environment: 'gprd',
};

{
  database_table_size_daily: periodicQuery.new({
    query: |||
      max by (relname, type, fqdn) (pg_total_relation_size_bytes{%(selectors)s})
    ||| % {
      selectors: selectors.serializeHash(defaultSelector),
    },
  }),
}
