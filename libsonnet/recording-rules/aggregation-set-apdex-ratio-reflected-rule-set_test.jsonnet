local underTest = import './aggregation-set-apdex-ratio-reflected-rule-set.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';

local fixture = aggregationSet.AggregationSet({
  id: 'component',
  name: 'Global Component SLI Metrics',
  intermediateSource: false,
  selector: {},
  labels: ['type', 'component'],
  supportedBurnRates: ['5m', '30m', '1h', '6h'],
  metricFormats: {
    apdexSuccessRate: 'apdex_success_%s',
    apdexWeight: 'apdex_weight_%s',
    apdexRatio: 'apdex_ratio_%s',
    opsRate: 'ops_rate_%s',
    errorRate: 'error_rate_%s',
    errorRatio: 'error_ratio_%s',
  },
});

test.suite({
  testRuleSet: {
    actual: underTest.aggregationSetApdexRatioReflectedRuleSet(fixture, '5m'),
    expect: [{
      record: 'apdex_ratio_5m',
      expr: |||
        sum by (type,component) (
          apdex_success_5m{}
        )
        /
        sum by (type,component) (
          apdex_weight_5m{}
        )
      |||,
    }],
  },
})
