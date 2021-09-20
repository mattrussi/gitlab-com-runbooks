local aggregationSet = import './aggregation-set.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

local fixture1 =
  aggregationSet.AggregationSet({
    selector: { x: 'Y' },
    labels: ['common_label_1', 'common_label_2'],
    burnRates: {
      '30m': {
        apdexRatio: 'target_30m_apdex_ratio',
      },
      '1h': {
        apdexRatio: 'target_1h_apdex_ratio',
      },
      '6h': {
        apdexRatio: 'target_6h_apdex_ratio',
      },
      '3d': {
        apdexRatio: 'target_3d_apdex_ratio',
      },
      '1m': {
        apdexRatio: 'target_1m_apdex_ratio',
        apdexWeight: 'target_1m_apdex_weight',
        opsRate: 'target_1m_ops_rate',
        errorRate: 'target_1m_error_rate',
        errorRatio: 'target_1m_error_ratio',
      },
      '5m': {
        apdexRatio: 'target_5m_apdex_ratio',
      },
    },
  });


test.suite({
  testGetApdexRatioMetricForBurnRate: {
    actual: fixture1.getApdexRatioMetricForBurnRate('1m'),
    expect: 'target_1m_apdex_ratio',
  },
  testGetApdexWeightMetricForBurnRate: {
    actual: fixture1.getApdexWeightMetricForBurnRate('1m'),
    expect: 'target_1m_apdex_weight',
  },
  testGetOpsRateMetricForBurnRate: {
    actual: fixture1.getOpsRateMetricForBurnRate('1m'),
    expect: 'target_1m_ops_rate',
  },
  testGetErrorRateMetricForBurnRate: {
    actual: fixture1.getErrorRateMetricForBurnRate('1m'),
    expect: 'target_1m_error_rate',
  },
  testGetErrorRatioMetricForBurnRate: {
    actual: fixture1.getErrorRatioMetricForBurnRate('1m'),
    expect: 'target_1m_error_ratio',
  },
  testMissingErrorRatioMetricForBurnRate: {
    actual: fixture1.getErrorRatioMetricForBurnRate('5m'),
    expect: null,
  },
  testGetBurnRates: {
    actual: fixture1.getBurnRates(),
    expect: ['1m', '5m', '30m', '1h', '6h', '3d'],
  },
})
