local graph_basic = import '../grafana/basic.libsonnet';
local timeseries_basic = import '../grafana/basic_timeseries.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

local title = 'Test Panel';
local linewidth = 1;
local fill = 0;
local datasource = '$PROMETHEUS_DS';
local description = '';
local decimals = 2;
local sort = 'desc';
local legend_show = true;
local legend_values = true;
local legend_min = true;
local legend_max = true;
local legend_current = true;
local legend_total = false;
local legend_avg = true;
local legend_alignAsTable = true;
local legend_hideEmpty = true;
local legend_rightSide = false;
local thresholds = [];
local points = false;
local pointradius = 5;
local stableId = null;
local lines = true;
local stack = false;
local bars = false;

test.suite({
  testGraphPanel: {
    expect: graph_basic_timeseries.graphPanel(title, linewidth, fill, datasource, description, decimals, sort, legend_show, legend_values, legend_min, legend_max, legend_current, legend_total, legend_avg, legend_alignAsTable, legend_hideEmpty, legend_rightSide, thresholds, points, pointradius, stableId, lines, stack, bars),
    actual: timeseries_basic_timeseries.graphPanel(title, linewidth, fill, datasource, description, decimals, sort, legend_show, legend_values, legend_min, legend_max, legend_current, legend_total, legend_avg, legend_alignAsTable, legend_hideEmpty, legend_rightSide, thresholds, points, pointradius, stableId, lines, stack, bars),
  },
})
