local sliHelper = import './service_level_indicator_helper.libsonnet';
local collectMetricNamesAndSelectors = sliHelper.collectMetricNamesAndSelectors;
local test = import 'test.libsonnet';

test.suite({
  testCollectMetricNamesAndSelectorsEmptyArray: {
    actual: collectMetricNamesAndSelectors([]),
    expect: {},
  },
  testCollectMetricNamesAndSelectorsArrayOfEmptyHashes: {
    actual: collectMetricNamesAndSelectors([{}, {}, {}]),
    expect: {},
  },
  testCollectMetricNamesAndSelectorsDifferentLabels: {
    actual: collectMetricNamesAndSelectors([
      { metric_foo: { type: 'foo' } },
      { metric_bar: { job: 'bar' } },
    ]),
    expect: {
      metric_foo: { type: ['foo'] },
      metric_bar: { job: ['bar'] },
    },
  },
  testCollectMetricNamesAndSelectorsSameLabels: {
    actual: collectMetricNamesAndSelectors([
      { metric_foo: { type: 'foo' } },
      { metric_foo: { type: 'bar' } },
    ]),
    expect: {
      metric_foo: { type: ['bar', 'foo'] },
    },
  },
  testCollectMetricNamesAndSelectorsMultipleHashes: {
    actual: collectMetricNamesAndSelectors([
      { metric_foo: { type: 'foo', job: 'bar' } },
      { metric_foo: { type: 'foo', job: 'baz' } },
      { metric_boo: { type: 'boo' } },
      { metric_boo: { job: 'boo' } },
    ]),
    expect: {
      metric_foo: { type: ['foo'], job: ['bar', 'baz'] },
      metric_boo: { type: ['boo'], job: ['boo'] },
    },
  },
  testCollectMetricNamesAndSelectorsEmptyStringLabelValue: {
    actual: collectMetricNamesAndSelectors([
      { metric_foo: { type: 'foo', le: '' } },
      { metric_foo: { type: 'foo' } },
    ]),
    expect: {
      metric_foo: { type: ['foo'], le: [''] },
    },
  },
})
