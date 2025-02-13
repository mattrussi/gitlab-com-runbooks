local promQuery = import './prom_query.libsonnet';
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
    actual: promQuery.timeSeriesTarget(expr, format, intervalFactor, legendFormat, datasource, interval, instant),
  },
})
