local periodicQuery = import './periodic-query.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local defaultSelector = {
  env: 'gprd',
  environment: 'gprd',
  type: 'patroni',
};

{
  database_table_size_daily: periodicQuery.new({
    query: |||
      sort_desc(max by (relname)(pg_total_relation_size_bytes{%(selectors)s}))
    ||| % {
      selectors: selectors.serializeHash(defaultSelector),
    },
  }),
}
