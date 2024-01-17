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
      metric_foo: { type: { oneOf: ['foo'] } },
      metric_bar: { job: { oneOf: ['bar'] } },
    },
  },
  testCollectMetricNamesAndSelectorsSameLabels: {
    actual: collectMetricNamesAndSelectors([
      { metric_foo: { type: 'foo' } },
      { metric_foo: { type: 'bar' } },
    ]),
    expect: {
      metric_foo: { type: { oneOf: ['bar', 'foo'] } },
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
      metric_foo: { type: { oneOf: ['foo'] }, job: { oneOf: ['bar', 'baz'] } },
      metric_boo: { type: { oneOf: ['boo'] }, job: { oneOf: ['boo'] } },
    },
  },
  testCollectMetricNamesAndSelectorsEmptyStringLabelValue: {
    actual: collectMetricNamesAndSelectors([
      { metric_foo: { type: 'foo', le: '' } },
      { metric_foo: { type: 'foo' } },
    ]),
    expect: {
      metric_foo: { type: { oneOf: ['foo'] }, le: { oneOf: [''] } },
    },
  },
  testCollectMetricNamesAndSelectorsNestedSelector1: {
    actual: collectMetricNamesAndSelectors([
      { metric_foo: { code: { re: '^5.*' } } },
      { metric_foo: { code: { re: '^4.*' } } },
    ]),
    expect: { metric_foo: { code: { oneOf: ['^4.*', '^5.*'] } } },
  },
  testCollectMetricNamesAndSelectorsNestedSelector2: {
    actual: collectMetricNamesAndSelectors([
      { metric_foo: { code: { re: '^5.*' }, type: 'foo' } },
      { metric_foo: { code: { re: '^4.*' }, type: 'bar' } },
    ]),
    expect: {
      metric_foo: {
        code: { oneOf: ['^4.*', '^5.*'] },
        type: { oneOf: ['bar', 'foo'] },
      },
    },
  },
  testCollectMetricNamesAndSelectorsNestedSelector3: {
    actual: collectMetricNamesAndSelectors([
      { metric_foo: { code: { re: '^4.*|^5.*', ne: '200' } } },
      { metric_foo: { code: { re: '^4.*', nre: '^2.*' } } },
    ]),
    expect: { metric_foo: { code: { oneOf: ['^4.*', '^5.*'] } } },
  },
  testCollectMetricNamesAndSelectorsNestedSelector4: {
    actual: collectMetricNamesAndSelectors([
      { metric_foo: { backend: { oneOf: ['a', 'b'] } } },
      { metric_foo: { backend: { oneOf: ['c', 'd'] } } },
      { metric_foo: { backend: { oneOf: ['e', 'f'] } } },
    ]),
    expect: { metric_foo: { backend: { oneOf: ['a', 'b', 'c', 'd', 'e', 'f'] } } },
  },
  testCollectMetricNamesAndSelectorsNestedSelector5: {
    actual: collectMetricNamesAndSelectors(
      [
        { some_total: { backend: { oneOf: ['web'] }, code: { oneOf: ['5xx'] } } },
        { some_total: { backend: { oneOf: ['abc'] } } },
      ]
    ),
    expect: {
      some_total: {
        backend: { oneOf: ['abc', 'web'] },
        code: { oneOf: ['5xx'] },
      },
    },
  },

  testNormalizeSelectorHash1: {
    actual: sliHelper._normalizeSelectorExpression({ eq: 'a' }),
    expect: { oneOf: ['a'] },
  },
  testNormalizeSelectorHash2: {
    actual: sliHelper._normalizeSelectorExpression({ re: 'a' }),
    expect: { oneOf: ['a'] },
  },
  testNormalizeSelectorHash3: {
    actual: sliHelper._normalizeSelectorExpression({ re: 'a|b' }),
    expect: { oneOf: ['a', 'b'] },
  },
  testNormalizeSelectorHash4: {
    actual: sliHelper._normalizeSelectorExpression({ oneOf: ['a'] }),
    expect: { oneOf: ['a'] },
  },
  testNormalizeSelectorHash5: {
    actual: sliHelper._normalizeSelectorExpression({ ne: 'a' }),
    expect: {},
  },
  testNormalizeSelectorHash6: {
    actual: sliHelper._normalizeSelectorExpression({ nre: 'a|b' }),
    expect: {},
  },
  testNormalizeSelectorHash7: {
    actual: sliHelper._normalizeSelectorExpression({ noneOf: ['a', 'b'] }),
    expect: {},
  },
  testNormalizeSelectorHash8: {
    actual: sliHelper._normalizeSelectorExpression({ eq: 'a', re: 'b' }),
    expect: { oneOf: ['a', 'b'] },
  },
  testNormalizeSelectorHash9: {
    actual: sliHelper._normalizeSelectorExpression({ eq: 'a', re: 'a|b|c' }),
    expect: { oneOf: ['a', 'b', 'c'] },
  },
  testNormalizeSelectorHash10: {
    actual: sliHelper._normalizeSelectorExpression({ eq: 'a', oneOf: ['a', 'b', 'c'] }),
    expect: { oneOf: ['a', 'b', 'c'] },
  },
  testNormalizeSelectorHash11: {
    actual: sliHelper._normalizeSelectorExpression({ re: 'a|d|e|f', oneOf: ['a', 'b', 'c'] }),
    expect: { oneOf: ['a', 'b', 'c', 'd', 'e', 'f'] },
  },
  testNormalizeSimpleInt: {
    actual: sliHelper._normalize({ a: '1' }),
    expect: { a: { oneOf: ['1'] } },
  },
  testNormalizeSimpleStr: {
    actual: sliHelper._normalize({ a: 1 }),
    expect: { a: { oneOf: [1] } },
  },
  testNormalizeObject1: {
    actual: sliHelper._normalize({ a: { eq: '1' } }),
    expect: { a: { oneOf: ['1'] } },
  },
  testNormalizeObject2: {
    actual: sliHelper._normalize({ a: { eq: '1', re: '2' } }),
    expect: { a: { oneOf: ['1', '2'] } },
  },
  testNormalizeObject3: {
    actual: sliHelper._normalize({ a: [{ eq: '1' }, { re: '2' }] }),
    expect: { a: { oneOf: ['1', '2'] } },
  },
  testNormalizeObjectMultipleKeys: {
    actual: sliHelper._normalize({ a: '1', b: '2' }),
    expect: { a: { oneOf: ['1'] }, b: { oneOf: ['2'] } },
  },
  testNormalizeObjectWithNegativeExp: {
    actual: sliHelper._normalize({ a: { ne: '1', nre: '2|3' } }),
    expect: { a: {} },
  },
  testNormalizeObjectWithNegativeExp2: {
    actual: sliHelper._normalize({ a: { ne: '1', nre: '2|3', eq: '4', re: '1|2|5' } }),
    expect: { a: { oneOf: ['1', '2', '4', '5'] } },
  },
  testNormalizeObjectWithNegativeExp3: {
    actual: sliHelper._normalize({ a: [{ ne: '1' }, '2'] }),
    expect: { a: { oneOf: ['2'] } },
  },
  testMergeSelector1: {
    actual: sliHelper._mergeSelector(
      { a: '1' },
      { a: '1' },
    ),
    expect: { a: { oneOf: ['1'] } },
  },
  testMergeSelector2: {
    actual: sliHelper._mergeSelector(
      { a: '1' },
      { a: '2' },
    ),
    expect: { a: { oneOf: ['1', '2'] } },
  },
  testMergeSelector3: {
    actual: sliHelper._mergeSelector(
      { a: { eq: '1', re: '2|3' } },
      { a: { eq: '4', oneOf: ['5', '6'] } },
    ),
    expect: { a: { oneOf: ['1', '2', '3', '4', '5', '6'] } },
  },
  testMergeSelector4: {
    actual: sliHelper._mergeSelector(
      { a: [{ eq: '1' }, { re: '2|3' }] },
      { a: { eq: '4', oneOf: ['5', '6'] } },
    ),
    expect: { a: { oneOf: ['1', '2', '3', '4', '5', '6'] } },
  },
  testMergeSelector5: {
    actual: sliHelper._mergeSelector(
      { a: '1', b: '10' },
      { a: { re: '2|3|4', ne: '2' }, b: { re: '11|12' } },
    ),
    expect: {
      a: { oneOf: ['1', '2', '3', '4'] },
      b: { oneOf: ['10', '11', '12'] },
    },
  },
  testMergeSelector6: {
    actual: sliHelper._mergeSelector(
      { backend: { oneOf: ['web'] }, code: { oneOf: ['5xx'] } },
      { backend: { oneOf: ['abc'] } },
    ),
    expect: {
      backend: { oneOf: ['abc', 'web'] },
      code: { oneOf: ['5xx'] },
    },
  },
  testMergeSelector7: {
    actual: sliHelper._mergeSelector(
      { backend: { oneOf: ['web'] } },
      { backend: { oneOf: ['abc'] }, code: { oneOf: ['5xx'] } },
    ),
    expect: {
      backend: { oneOf: ['abc', 'web'] },
      code: { oneOf: ['5xx'] },
    },
  },
})
