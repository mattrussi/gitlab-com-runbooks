local promQuery = import './prom_query.libsonnet';
local target = import './time-series/target.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

local expr = 'up';
local format = 'time_series';
local intervalFactor = '1';
local legendFormat = '';
local datasource = null;
local interval = '1m';
local instant = null;

test.suite({
  testTarget: {
    expect: promQuery.target(expr, format, intervalFactor, legendFormat, datasource, interval, instant),
    actual: target.prometheus('foo', format, intervalFactor, legendFormat, datasource, interval, instant),
  },
})
