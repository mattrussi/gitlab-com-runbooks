local underTest = import './service_level_indicator_definition.libsonnet';
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local test = import 'test.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local successCounterApdex = metricsCatalog.successCounterApdex;
local histogramApdex = metricsCatalog.histogramApdex;
local errorCounterApdex = metricsCatalog.errorCounterApdex;
local combined = metricsCatalog.combined;

local testSli = underTest.serviceLevelIndicatorDefinition({
  significantLabels: [],
  userImpacting: false,
  requestRate: rateMetric('some_total_count'),
  apdex: successCounterApdex('some_apdex_success_total_count', 'some_apdex_total_count'),
  errorRate: rateMetric('some_error_total_count'),
}).initServiceLevelIndicatorWithName('test_sli', {});

local ratesAggregationSet = aggregationSet.AggregationSet({
  name: 'source',
  intermediateSource: true,
  labels: ['a', 'b'],
  selector: { hello: 'world' },
  metricFormats: {
    opsRate: 'source_ops:rate_%s',

    errorRate: 'source_error:rate_%s',
    errorRates: 'source_error:rates_%s',

    apdexRates: 'source_apdex:rates_%s',
    apdexSuccessRate: 'source_apdex:weight_rate_%s',
    apdexWeight: 'source_apdex:weight_rate_%s',
  },
  offset: '2s',
});

test.suite({
  testGenerateApdexRecordingRules: {
    actual: testSli.generateApdexRecordingRules('5m', ratesAggregationSet, { hello: 'world' }, { selector: 'is-present' }),
    expect: [
      {
        expr: |||
          sum by (a,b) (
            rate(some_apdex_success_total_count{selector="is-present"}[5m] offset 2s)
          )
        |||,
        labels: { hello: 'world' },
        record: 'source_apdex:weight_rate_5m',
      },
      {
        expr: |||
          sum by (a,b) (
            rate(some_apdex_total_count{selector="is-present"}[5m] offset 2s)
          )
        |||,
        labels: { hello: 'world' },
        record: 'source_apdex:weight_rate_5m',
      },
      {
        expr: |||
          label_replace(
            sum by (a,b) (
              rate(some_apdex_success_total_count{selector="is-present"}[5m] offset 2s)
            ),
            'recorded_rate', 'success_rate' , '', ''
          )
          or
          label_replace(
            sum by (a,b) (
              rate(some_apdex_total_count{selector="is-present"}[5m] offset 2s)
            ),
            'recorded_rate', 'apdex_weight' , '', ''
          )
        |||,
        labels: { hello: 'world' },
        record: 'source_apdex:rates_5m',
      },
    ],
  },
  testGenerateErrorRateRecordingRules: {
    actual: testSli.generateErrorRateRecordingRules('5m', ratesAggregationSet, { hello: 'world' }, { selector: 'is-present' }),
    expect: [
      {
        expr: |||
          (
            sum by (a,b) (
              rate(some_error_total_count{selector="is-present"}[5m] offset 2s)
            )
          )
          or
          (
            0 * group by(a,b) (
              source_ops:rate_5m{hello="world"}
            )
          )
        |||,
        labels: { hello: 'world' },
        record: 'source_error:rate_5m',
      },
      {
        expr: |||
          label_replace(
            sum by (a,b) (
              rate(some_error_total_count{selector="is-present"}[5m] offset 2s)
            )
            or
            (
              0 * sum by (a,b) (
                rate(some_total_count{selector="is-present"}[5m] offset 2s)
              )
            ),
            'recorded_rate', 'error_rate' , '', ''
          )
          or
          label_replace(
            sum by (a,b) (
              rate(some_total_count{selector="is-present"}[5m] offset 2s)
            ),
            'recorded_rate', 'ops_rate' , '', ''
          )
        |||,
        labels: { hello: 'world' },
        record: 'source_error:rates_5m',
      },
    ],
  },

  local testSliBase = {
    significantLabels: [],
    userImpacting: false,
  },

  local testSliWithSelectorHistogramApdex = underTest.serviceLevelIndicatorDefinition(testSliBase {
    apdex: histogramApdex('some_histogram_metrics', selector={ foo: 'bar' }),
    requestRate: rateMetric('some_total_count', selector={ label_a: 'bar' }),
    errorRate: rateMetric('some_total_count', selector={ label_b: 'foo' }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsHistogramApdex: {
    actual: testSliWithSelectorHistogramApdex.metricNamesAndLabels(),
    expect: {
      some_histogram_metrics: std.set(['foo', 'le']),
      some_total_count: std.set(['label_a', 'label_b']),
    },
  },

  local testSliWithSelectorSuccessCounterApdex = underTest.serviceLevelIndicatorDefinition(testSliBase {
    apdex: successCounterApdex(successRateMetric='success_total_count', operationRateMetric='some_total_count', selector={ foo: 'bar', baz: 'qux' }),
    requestRate: rateMetric('some_total_count', selector={ label_a: 'bar' }),
    errorRate: rateMetric('some_total_count', selector={ label_b: 'foo' }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsSuccessCounterApdex: {
    actual: testSliWithSelectorSuccessCounterApdex.metricNamesAndLabels(),
    expect: {
      success_total_count: std.set(['foo', 'baz']),
      some_total_count: std.set(['label_a', 'label_b', 'foo', 'baz']),
    },
  },

  local testSliWithSelectorErrorCounterApdex = underTest.serviceLevelIndicatorDefinition(testSliBase {
    apdex: errorCounterApdex(errorRateMetric='error_total_count', operationRateMetric='some_total_count', selector={ foo: 'bar', baz: 'qux' }),
    requestRate: rateMetric('some_total_count', selector={ label_a: 'bar' }),
    errorRate: rateMetric('some_total_count', selector={ label_b: 'foo' }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsErrorCounterApdex: {
    actual: testSliWithSelectorErrorCounterApdex.metricNamesAndLabels(),
    expect: {
      error_total_count: std.set(['foo', 'baz']),
      some_total_count: std.set(['label_a', 'label_b', 'foo', 'baz']),
    },
  },

  local testSliWithSelectorRequestRateOnly = underTest.serviceLevelIndicatorDefinition(testSliBase {
    requestRate: rateMetric('some_total_count', selector={ label_a: 'bar', type: 'foo' }),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsRequestRateOnly: {
    actual: testSliWithSelectorRequestRateOnly.metricNamesAndLabels(),
    expect: {
      some_total_count: std.set(['label_a', 'type']),
    },
  },

  local testSliWithoutSelector = underTest.serviceLevelIndicatorDefinition(testSliBase {
    apdex: histogramApdex('some_histogram_metrics'),
    requestRate: rateMetric('some_total_count'),
    errorRate: rateMetric('some_total_count'),
  }).initServiceLevelIndicatorWithName('test_sli', {}),
  testMetricNamesAndLabelsWithoutSelector: {
    actual: testSliWithoutSelector.metricNamesAndLabels(),
    expect: {
      some_histogram_metrics: ['le'],
      some_total_count: [],
    },
  },

  local testSliWithCombinedMetric = underTest.serviceLevelIndicatorDefinition(testSliBase {
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
  testMetricNamesAndLabelsWithCombinedMetric: {
    actual: testSliWithCombinedMetric.metricNamesAndLabels(),
    expect: {
      some_histogram_metrics: ['le'],
      pg_stat_database_xact_commit: std.set(['type', 'tier']),
      pg_stat_database_xact_rollback: std.set(['type', 'tier', 'some_label']),
      some_total_count: [],
    },
  },

})
