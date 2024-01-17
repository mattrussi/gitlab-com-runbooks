local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local test = import 'test.libsonnet';

local testSli = metricsCatalog.combinedServiceLevelIndicatorDefinition(
  userImpacting=false,
  featureCategory='not_owned',
  description='',
  components=[
    metricsCatalog.serviceLevelIndicatorDefinition({
      userImpacting: false,
      significantLabels: ['hello'],
      requestRate: rateMetric(
        counter='some_total',
        selector={ foo: 'bar', backend: 'web' }
      ),
      errorRate: rateMetric(
        counter='some_total',
        selector={ foo: 'bar', backend: 'web', code: '5xx' }
      ),
    }),
    metricsCatalog.serviceLevelIndicatorDefinition({
      userImpacting: false,
      significantLabels: ['world'],
      requestRate: rateMetric(
        counter='some_total',
        selector={ foo: 'bar', backend: 'abc', type: 'baz' }
      ),
      errorRate: rateMetric(
        counter='some_total',
        selector={ foo: 'bar', backend: 'abc', type: 'baz', code: '5xx' }
      ),
    }),
    metricsCatalog.serviceLevelIndicatorDefinition({
      userImpacting: false,
      significantLabels: [],
      requestRate: rateMetric(
        counter='some_other_total',
        selector={ foo: 'bar', backend: 'abc' }
      ),
      errorRate: rateMetric(
        counter='some_other_total',
        selector={ foo: 'bar', backend: 'abc', code: '5xx' }
      ),
    }),
  ],
).initServiceLevelIndicatorWithName('test_sli', {});

test.suite({
  testMetricNamesAndLabelsCombined: {
    actual: testSli.metricNamesAndLabels(),
    expect: {
      some_total: std.set(['foo', 'backend', 'code', 'type', 'hello', 'world']),
      some_other_total: std.set(['foo', 'backend', 'code', 'hello', 'world']),
    },
  },
  testMetricNamesAndSelectorsCombined: {
    actual: testSli.metricNamesAndSelectors(),
    expect: {
      some_total: {
        foo: { oneOf: ['bar'] },
        backend: { oneOf: ['abc', 'web'] },
        type: { oneOf: ['baz'] },
        code: { oneOf: ['5xx'] },
        hello: { oneOf: [''] },
        world: { oneOf: [''] },
      },
      some_other_total: {
        foo: { oneOf: ['bar'] },
        backend: { oneOf: ['abc'] },
        code: { oneOf: ['5xx'] },
        hello: { oneOf: [''] },
        world: { oneOf: [''] },
      },
    },
  },
})
