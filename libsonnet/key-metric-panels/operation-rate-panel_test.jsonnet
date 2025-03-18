local operationRatePanel = import './operation-rate-panel.libsonnet';
local aggregationSets = (import '../../metrics-catalog/gitlab-metrics-config.libsonnet').aggregationSets;
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

local title = 'test-title';
local aggregationSet = aggregationSets.serviceSLIs;
local selectorHash = { type: 'test-service' };
local stableId = 'test-id';
local legendFormat = 'test-format';
local expectMultipleSeries = false;
local includePredictions = false;
local includeLastWeek = true;
local compact = false;

test.suite({
  testTarget: {
    expect: operationRatePanel.panel(
      title=title,
      aggregationSet=aggregationSet,
      selectorHash=selectorHash,
      stableId=stableId,
      legendFormat=legendFormat,
      expectMultipleSeries=expectMultipleSeries,
      includePredictions=includePredictions,
      includeLastWeek=includeLastWeek,
      compact=compact,
    ),
    actual: operationRatePanel.timeSeriesPanel(
      title=title,
      aggregationSet=aggregationSet,
      selectorHash=selectorHash,
      stableId=stableId,
      legendFormat=legendFormat,
      expectMultipleSeries=expectMultipleSeries,
      includePredictions=includePredictions,
      includeLastWeek=includeLastWeek,
      compact=compact,
    ),
  },
})
