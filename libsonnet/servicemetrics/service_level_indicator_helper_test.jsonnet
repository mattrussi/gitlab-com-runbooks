local sliDefinition = import './service_level_indicator_definition.libsonnet';
local sliHelper = import './service_level_indicator_helper.libsonnet';
local collectMetricNamesAndSelectors = sliHelper.collectMetricNamesAndSelectors;
local test = import 'test.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local successCounterApdex = metricsCatalog.successCounterApdex;
local errorCounterApdex = metricsCatalog.errorCounterApdex;
local combined = metricsCatalog.combined;
local rateMetric = metricsCatalog.rateMetric;
local derivMetric = metricsCatalog.derivMetric;
local gaugeMetric = metricsCatalog.gaugeMetric;
local combinedSli = import './combined_service_level_indicator_definition.libsonnet';

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
      metric_boo: { type: {}, job: {} },
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
        code: {},
      },
    },
  },
  testCollectMetricNamesAndSelectorsNestedSelector6: {
    actual: collectMetricNamesAndSelectors(
      [
        { some_total: { backend: { oneOf: ['web'] } } },
        { some_total: { backend: { oneOf: ['abc'] }, code: { oneOf: ['5xx'] } } },
      ]
    ),
    expect: {
      some_total: {
        backend: { oneOf: ['abc', 'web'] },
        code: {},
      },
    },
  },
  testCollectMetricNamesAndSelectorsNestedSelector7: {
    actual: collectMetricNamesAndSelectors(
      [
        { some_total: { backend: { oneOf: ['web'] } } },
        {},
      ]
    ),
    expect: {
      some_total: {
        backend: { oneOf: ['web'] },
      },
    },
  },
  testCollectMetricNamesAndSelectorsNestedSelector8: {
    actual: collectMetricNamesAndSelectors(
      [
        { some_total: { backend: { oneOf: ['web'] } } },
        { some_total: {} },
      ]
    ),
    expect: {
      some_total: {
        backend: {},
      },
    },
  },

  testNormalizeSelectorHashEmpty: {
    actual: sliHelper._normalizeSelectorExpression({}),
    expect: {},
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
      code: {},
    },
  },
  testMergeSelector7: {
    actual: sliHelper._mergeSelector(
      { backend: { oneOf: ['web'] } },
      { backend: { oneOf: ['abc'] }, code: { oneOf: ['5xx'] } },
    ),
    expect: {
      backend: { oneOf: ['abc', 'web'] },
      code: {},
    },
  },
  testMergeSelector8: {
    actual: sliHelper._mergeSelector(
      { backend: {} },
      { backend: {} },
    ),
    expect: {
      backend: {},
    },
  },
  testMergeSelector9: {
    actual: sliHelper._mergeSelector(
      { code: '500' },
      {},
    ),
    expect: { code: {} },
  },

  local testSliBase = {
    significantLabels: [],
    userImpacting: false,
  },

  local testMetricsDescriptorAggregationLabels(sliDefinition, expect) = {
    local descriptor = sliHelper.sliMetricsDescriptor(sliDefinition),
    actual: descriptor.metricNamesAndAggregationLabels(),
    expect: expect,
  },
  local testMetricsDescriptorSelectors(sliDefinition, expect) = {
    local descriptor = sliHelper.sliMetricsDescriptor(sliDefinition),
    actual: descriptor.metricNamesAndSelectors(),
    expect: expect,
  },

  local testSliWithSelectorHistogramApdex = sliDefinition.serviceLevelIndicatorDefinition(testSliBase {
    apdex: histogramApdex('some_histogram_metrics', selector={ foo: 'bar' }),
    requestRate: rateMetric('some_total_count', selector={ label_a: 'bar' }),
    errorRate: rateMetric('some_total_count', selector={ label_b: 'foo' }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsHistogramApdex: testMetricsDescriptorAggregationLabels(
    testSliWithSelectorHistogramApdex,
    expect={
      some_histogram_metrics: std.set(['foo', 'le']),
      some_total_count: std.set(['label_a', 'label_b']),
    }
  ),
  testMetricNamesAndSelectorsHistogramApdex: testMetricsDescriptorSelectors(
    testSliWithSelectorHistogramApdex,
    expect={
      some_histogram_metrics: {
        foo: { oneOf: ['bar'] },
      },
      some_total_count: {
        label_a: {},
        label_b: {},
      },

    }
  ),

  local testSliWithSelectorSuccessCounterApdex = sliDefinition.serviceLevelIndicatorDefinition(testSliBase {
    apdex: successCounterApdex(successRateMetric='success_total_count', operationRateMetric='some_total_count', selector={ foo: 'bar', baz: 'qux' }),
    requestRate: rateMetric('some_total_count', selector={ label_a: 'bar' }),
    errorRate: rateMetric('some_total_count', selector={ label_b: 'foo' }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsSuccessCounterApdex: testMetricsDescriptorAggregationLabels(
    testSliWithSelectorSuccessCounterApdex,
    expect={
      success_total_count: std.set(['foo', 'baz']),
      some_total_count: std.set(['label_a', 'label_b', 'foo', 'baz']),
    }
  ),
  testMetricNamesAndSelectorsSuccessCounterApdex: testMetricsDescriptorSelectors(
    testSliWithSelectorSuccessCounterApdex,
    expect={
      success_total_count: {
        foo: { oneOf: ['bar'] },
        baz: { oneOf: ['qux'] },
      },
      some_total_count: {
        foo: {},
        baz: {},
        label_a: {},
        label_b: {},
      },
    }
  ),

  local testSliWithSelectorErrorCounterApdex = sliDefinition.serviceLevelIndicatorDefinition(testSliBase {
    apdex: errorCounterApdex(errorRateMetric='error_total_count', operationRateMetric='some_total_count', selector={ foo: 'bar', baz: 'qux' }),
    requestRate: rateMetric('some_total_count', selector={ label_a: 'bar' }),
    errorRate: rateMetric('some_total_count', selector={ label_b: 'foo' }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsErrorCounterApdex: testMetricsDescriptorAggregationLabels(
    testSliWithSelectorErrorCounterApdex,
    expect={
      error_total_count: std.set(['foo', 'baz']),
      some_total_count: std.set(['label_a', 'label_b', 'foo', 'baz']),
    },
  ),
  testMetricNamesAndSelectorsErrorCounterApdex: testMetricsDescriptorSelectors(
    testSliWithSelectorErrorCounterApdex,
    expect={
      error_total_count: {
        foo: { oneOf: ['bar'] },
        baz: { oneOf: ['qux'] },
      },
      some_total_count: {
        foo: {},
        baz: {},
        label_a: {},
        label_b: {},
      },
    },
  ),

  local testSliWithSelectorRequestRateOnly = sliDefinition.serviceLevelIndicatorDefinition(testSliBase {
    requestRate: rateMetric('some_total_count', selector={ label_a: 'bar', type: 'foo' }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsRequestRateOnly: testMetricsDescriptorAggregationLabels(
    testSliWithSelectorRequestRateOnly,
    expect={
      some_total_count: std.set(['label_a', 'type']),
    },
  ),
  testMetricNamesAndSelectorsRequestRateOnly: testMetricsDescriptorSelectors(
    testSliWithSelectorRequestRateOnly,
    expect={
      some_total_count: {
        label_a: { oneOf: ['bar'] },
        type: { oneOf: ['foo'] },
      },
    },
  ),

  local testSliWithoutSelector = sliDefinition.serviceLevelIndicatorDefinition(testSliBase {
    apdex: histogramApdex('some_histogram_metrics'),
    requestRate: rateMetric('some_total_count'),
    errorRate: rateMetric('some_total_count'),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsWithoutSelector: testMetricsDescriptorAggregationLabels(
    testSliWithoutSelector,
    expect={
      some_histogram_metrics: ['le'],
      some_total_count: [],
    },
  ),
  testMetricNamesAndSelectorsWithoutSelector: testMetricsDescriptorSelectors(
    testSliWithoutSelector,
    expect={
      some_histogram_metrics: {},
      some_total_count: {},
    },
  ),

  local testSliWithCombinedMetric = sliDefinition.serviceLevelIndicatorDefinition(testSliBase {
    apdex: histogramApdex('some_histogram_metrics'),
    requestRate: combined([
      rateMetric(
        counter='pg_stat_database_xact_commit',
        selector={ type: 'patroni', tier: 'db' },
        instanceFilter='(pg_replication_is_replica == 0)'
      ),
      rateMetric(
        counter='pg_stat_database_xact_rollback',
        selector={ type: 'patroni', tier: 'db', some_label: 'true' },
        instanceFilter='(pg_replication_is_replica == 0)'
      ),
    ]),
    errorRate: rateMetric('some_total_count'),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsWithCombinedMetric: testMetricsDescriptorAggregationLabels(
    testSliWithCombinedMetric,
    expect={
      some_histogram_metrics: ['le'],
      pg_stat_database_xact_commit: std.set(['type', 'tier']),
      pg_stat_database_xact_rollback: std.set(['type', 'tier', 'some_label']),
      some_total_count: [],
    },
  ),
  testMetricNamesAndSelectorsWithCombinedMetric: testMetricsDescriptorSelectors(
    testSliWithCombinedMetric,
    expect={
      pg_stat_database_xact_commit: { tier: { oneOf: ['db'] }, type: { oneOf: ['patroni'] } },
      pg_stat_database_xact_rollback: { some_label: { oneOf: ['true'] }, tier: { oneOf: ['db'] }, type: { oneOf: ['patroni'] } },
      some_histogram_metrics: {},
      some_total_count: {},
    },
  ),

  local testSliWithDerivMetric = sliDefinition.serviceLevelIndicatorDefinition(testSliBase {
    requestRate: derivMetric('some_total_count', { type: 'foo', job: 'bar' }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsDerivMetric: testMetricsDescriptorAggregationLabels(
    testSliWithDerivMetric,
    expect={
      some_total_count: ['job', 'type'],
    },
  ),
  testMetricNamesAndSelectorsDerivMetric: testMetricsDescriptorSelectors(
    testSliWithDerivMetric,
    expect={
      some_total_count: {
        type: { oneOf: ['foo'] },
        job: { oneOf: ['bar'] },
      },
    },
  ),

  local testSliWithGaugeMetric = sliDefinition.serviceLevelIndicatorDefinition(testSliBase {
    requestRate: gaugeMetric('some_total_count', { type: 'foo', job: 'bar' }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsGaugeMetric: testMetricsDescriptorAggregationLabels(
    testSliWithGaugeMetric,
    expect={
      some_total_count: ['job', 'type'],
    },
  ),
  testMetricNamesAndSelectorsGaugeMetric: testMetricsDescriptorSelectors(
    testSliWithGaugeMetric,
    expect={
      some_total_count: {
        type: { oneOf: ['foo'] },
        job: { oneOf: ['bar'] },
      },
    },
  ),

  local testSliWithMultipleSelectors = sliDefinition.serviceLevelIndicatorDefinition(testSliBase {
    requestRate: rateMetric('some_total_count', { type: 'foo', job: { re: 'hello|world' } }),
    errorRate: rateMetric('some_total_count', { type: 'bar', job: { eq: 'boo' } }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsMultipleSelectors: testMetricsDescriptorAggregationLabels(
    testSliWithMultipleSelectors,
    expect={
      some_total_count: ['job', 'type'],
    },
  ),
  testMetricNamesAndSelectorsMultipleSelectors: testMetricsDescriptorSelectors(
    testSliWithMultipleSelectors,
    expect={
      some_total_count: {
        type: { oneOf: ['bar', 'foo'] },
        job: { oneOf: ['boo', 'hello', 'world'] },
      },
    },
  ),

  local testSliWithSignificantLabels = sliDefinition.serviceLevelIndicatorDefinition(testSliBase {
    requestRate: rateMetric('some_total_count', { type: 'foo', job: { re: 'hello|world' } }),
    errorRate: rateMetric('some_total_count', { type: 'bar', job: { eq: 'boo' } }),
    significantLabels: ['fizz', 'buzz'],
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsSignificantLabels: testMetricsDescriptorAggregationLabels(
    testSliWithSignificantLabels,
    expect={
      some_total_count: std.set(['fizz', 'buzz', 'job', 'type']),
    }
  ),
  testMetricNamesAndSelectorsSignificantLabels: testMetricsDescriptorSelectors(
    testSliWithSignificantLabels,
    expect={
      some_total_count: {
        type: { oneOf: ['bar', 'foo'] },
        job: { oneOf: ['boo', 'hello', 'world'] },
      },
    },
  ),

  local testCombinedSli = combinedSli.combinedServiceLevelIndicatorDefinition(
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
  ).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsCombinedSli: testMetricsDescriptorAggregationLabels(
    testCombinedSli,
    expect={
      some_total: std.set(['foo', 'backend', 'code', 'type', 'hello', 'world']),
      some_other_total: std.set(['foo', 'backend', 'code', 'hello', 'world']),
    }
  ),
  testMetricNamesAndSelectorsCombinedSli: testMetricsDescriptorSelectors(
    testCombinedSli,
    expect={
      some_total: {
        foo: { oneOf: ['bar'] },
        backend: { oneOf: ['abc', 'web'] },
        type: {},
        code: {},
      },
      some_other_total: {
        foo: { oneOf: ['bar'] },
        backend: { oneOf: ['abc'] },
        code: {},
      },
    },
  ),
})
