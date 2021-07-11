local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local metricsCatalog = import './metrics-catalog.libsonnet';

test.suite({
  testBlank: {
    actual: metricsCatalog.listServiceLevelIndicatorsForFeatureCategories(['not_owned']),
    expectThat: function(x) std.length(x) > 0,
  },
})
