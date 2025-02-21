local basic = import './basic.libsonnet';
local panel = import './time-series/panel.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

local row = grafana.row;

local testStableIdDashboard =
  basic.dashboard('Test', [])
  .addPanels([
    basic.graphPanel('TEST', stableId='test-graph-panel'),
  ])
  .addPanel(
    row.new(title='Row', collapse=true)
    .addPanels([
      basic.graphPanel('TEST', stableId='collapsed-panel'),
    ]),
    gridPos={
      x: 0,
      y: 500,
      w: 24,
      h: 1,
    }
  )
  .trailer();

test.suite({
  testStableIds: {
    actual: testStableIdDashboard,
    expectThat: function(dashboard) dashboard.panels[0].id == 162106516,  // stableId for test-graph-panel
  },
  testNestedStableIds: {
    actual: testStableIdDashboard,
    expectThat: function(dashboard) dashboard.panels[1].panels[0].id == 3457099265,  // stableId for collapsed-panel
  },
  local title = 'Test Panel',
  local linewidth = 1,
  local fill = 0,
  local datasource = '$PROMETHEUS_DS',
  local description = '',
  local decimals = 2,
  local sort = 'desc',
  local legend_show = true,
  local legend_values = true,
  local legend_min = true,
  local legend_max = true,
  local legend_current = true,
  local legend_total = false,
  local legend_avg = true,
  local legend_alignAsTable = true,
  local legend_hideEmpty = true,
  local legend_rightSide = false,
  local thresholds = [],
  local points = false,
  local pointradius = 5,
  local stableId = null,
  local lines = true,
  local stack = false,
  local bars = false,
  local promQuery = import 'grafana/prom_query.libsonnet',
  local sliPromQL = import './sli_promql.libsonnet',


  testTimeSeriesPanel: {
    expect: basic.graphPanel(title, linewidth, fill, datasource, description, decimals, sort, legend_show, legend_values, legend_min, legend_max, legend_current, legend_total, legend_avg, legend_alignAsTable, legend_hideEmpty, legend_rightSide, thresholds, points, pointradius, stableId, lines, stack, bars),
    actual: panel.basic(title, linewidth, description, datasource, legend_show, legend_min, legend_max, legend_current, legend_total, legend_avg, legend_alignAsTable, legend_rightSide, points, pointradius, lines)(title, linewidth, fill, datasource, description, decimals, sort, legend_show, legend_values, legend_min, legend_max, legend_current, legend_total, legend_avg, legend_alignAsTable, legend_hideEmpty, legend_rightSide, thresholds, points, pointradius, stableId, lines, stack, bars).addTarget(
      promQuery.timeSeriesTarget(
        sliPromQL.opsRate.serviceOpsRatePrediction({}, 1),
        legendFormat='upper normal',
      ),
    ),
  },
})
