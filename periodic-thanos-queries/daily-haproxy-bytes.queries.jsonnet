local periodicQuery = import './periodic-query.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local defaultSelector = {
  env: 'gprd',
  environment: 'gprd',
  device: { ne: 'lo' },
  backend: { re: '.*api$' },
};
local interval = '1d';

{
  total_haproxy_bytes_out: periodicQuery.new({
    query: |||
      sum(increase(haproxy_backend_bytes_out_total{%(selectors)s}[%(interval)s]))
    ||| % {
      selectors: selectors.serializeHash(defaultSelector),
      interval: interval,
    },
  }),
}
