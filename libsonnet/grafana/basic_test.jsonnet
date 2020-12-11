local basic = import './basic.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

local testStableIdDashboard =
  basic.dashboard('Test', [])
  .addPanels([
    basic.graphPanel('TEST', stableId='test-graph-panel'),
  ])
  .trailer();

test.suite({
  testStableIds: {
    actual: testStableIdDashboard,
    expectThat: function(dashboard) dashboard.panels[0].id == 39560,  // stableId for test-graph-panel
  },
})
