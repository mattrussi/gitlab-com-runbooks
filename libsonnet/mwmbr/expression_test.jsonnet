local expression = import './expression.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local aggregationSet = import 'servicemetrics/aggregation-set.libsonnet';

local testAggregationSet = aggregationSet.AggregationSet({
  name: 'Test',
  intermediateSource: false,
  selector: { monitor: 'global' },  // Not Thanos Ruler
  labels: ['environment', 'tier', 'type', 'stage'],
  burnRates: {
    '5m': {
      apdexRatio: 'apdex:ratio_5m',
      apdexWeight: 'apdex:weight:score_5m',
      opsRate: 'operation:rate_5m',
      errorRate: 'error:rate_5m',
      errorRatio: 'error:ratio_5m',
    },
    '30m': {
      apdexRatio: 'apdex:ratio_30m',
      apdexWeight: 'apdex:weight:score_30m',
      opsRate: 'operation:rate_30m',
      errorRate: 'error:rate_30m',
      errorRatio: 'error:ratio_30m',
    },
    '1h': {
      apdexRatio: 'apdex:ratio_1h',
      apdexWeight: 'apdex:weight:score_1h',
      opsRate: 'operation:rate_1h',
      errorRate: 'error:rate_1h',
      errorRatio: 'error:ratio_1h',
    },
    '6h': {
      apdexRatio: 'apdex:ratio_6h',
      apdexWeight: 'apdex:weight:score_6h',
      opsRate: 'operation:rate_6h',
      errorRate: 'error:rate_6h',
      errorRatio: 'error:ratio_6h',
    },
    '3d': {
      apdexRatio: 'apdex:ratio_3d',
      apdexWeight: 'apdex:weight:score_3d',
      opsRate: 'operation:rate_3d',
      errorRate: 'error:rate_3d',
      errorRatio: 'error:ratio_3d',
    },
  },
});


test.suite({
  testErrorBurnWithoutMinimumRate: {
    actual: expression.multiburnRateErrorExpression(
      aggregationSet=testAggregationSet,
      thresholdSLOValue=0.99,
      metricSelectorHash={ type: 'web' },
      alertForDuration='5m'
    ),
    expect: |||
      (
        last_over_time(error:ratio_1h{monitor="global",type="web"}[5m])
        > (14.4 * 0.990000)
      )
      and
      (
        last_over_time(error:ratio_5m{monitor="global",type="web"}[5m])
        > (14.4 * 0.990000)
      )
      or
      (
        last_over_time(error:ratio_6h{monitor="global",type="web"}[5m])
        > (6 * 0.990000)
      )
      and
      (
        last_over_time(error:ratio_30m{monitor="global",type="web"}[5m])
        > (6 * 0.990000)
      )
    |||,
  },


  testErrorBurnWithThreshold: {
    actual: expression.multiburnRateErrorExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      minimumSamplesForMonitoring=3600 * 10,
      thresholdSLOValue=0.01,
      alertForDuration='4m'
    ),
    expect: |||
      (
        (
          last_over_time(error:ratio_1h{monitor="global",type="web"}[4m])
          > (14.4 * 0.010000)
        )
        and
        (
          last_over_time(error:ratio_5m{monitor="global",type="web"}[4m])
          > (14.4 * 0.010000)
        )
        or
        (
          last_over_time(error:ratio_6h{monitor="global",type="web"}[4m])
          > (6 * 0.010000)
        )
        and
        (
          last_over_time(error:ratio_30m{monitor="global",type="web"}[4m])
          > (6 * 0.010000)
        )
      )
      and on(environment,tier,type,stage)
      (
        sum by(environment,tier,type,stage) (
          last_over_time(operation:rate_1h{monitor="global",type="web"}[4m])
        ) >= 10
      )
    |||,
  },

  testApdexBurnWithoutMinimumRate: {
    actual: expression.multiburnRateApdexExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      thresholdSLOValue=0.99,
      alertForDuration='5m'
    ),
    expect: |||
      (
        last_over_time(apdex:ratio_1h{monitor="global",type="web"}[5m])
        < (1 - 14.4 * 0.010000)
      )
      and
      (
        last_over_time(apdex:ratio_5m{monitor="global",type="web"}[5m])
        < (1 - 14.4 * 0.010000)
      )
      or
      (
        last_over_time(apdex:ratio_6h{monitor="global",type="web"}[5m])
        < (1 - 6 * 0.010000)
      )
      and
      (
        last_over_time(apdex:ratio_30m{monitor="global",type="web"}[5m])
        < (1 - 6 * 0.010000)
      )
    |||,
  },

  testApdexBurnWithThreshold: {
    actual: expression.multiburnRateApdexExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      thresholdSLOValue=0.9995,
      alertForDuration='5m'
    ),
    expect: |||
      (
        last_over_time(apdex:ratio_1h{monitor="global",type="web"}[5m])
        < (1 - 14.4 * 0.000500)
      )
      and
      (
        last_over_time(apdex:ratio_5m{monitor="global",type="web"}[5m])
        < (1 - 14.4 * 0.000500)
      )
      or
      (
        last_over_time(apdex:ratio_6h{monitor="global",type="web"}[5m])
        < (1 - 6 * 0.000500)
      )
      and
      (
        last_over_time(apdex:ratio_30m{monitor="global",type="web"}[5m])
        < (1 - 6 * 0.000500)
      )
    |||,
  },

  testApdexBurnWithMinimumSamples1h: {
    actual: expression.multiburnRateApdexExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      thresholdSLOValue=0.99,
      windows=['1h'],
      minimumSamplesForMonitoring=60,
      operationRateWindowDuration='1h',
      alertForDuration='5m'
    ),
    expect: |||
      (
        (
          last_over_time(apdex:ratio_1h{monitor="global",type="web"}[5m])
          < (1 - 14.4 * 0.010000)
        )
        and
        (
          last_over_time(apdex:ratio_5m{monitor="global",type="web"}[5m])
          < (1 - 14.4 * 0.010000)
        )
      )
      and on(environment,tier,type,stage)
      (
        sum by(environment,tier,type,stage) (
          last_over_time(operation:rate_1h{monitor="global",type="web"}[5m])
        ) >= 0.01667
      )
    |||,
  },

  testErrorBurnWithMinimumSamples3d: {
    actual: expression.multiburnRateErrorExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      thresholdSLOValue=0.99,
      windows=['3d'],
      minimumSamplesForMonitoring=60,
      operationRateWindowDuration='3d',
      alertForDuration='5m'
    ),
    expect: |||
      (
        (
          last_over_time(error:ratio_3d{monitor="global",type="web"}[5m])
          > (1 * 0.990000)
        )
        and
        (
          last_over_time(error:ratio_6h{monitor="global",type="web"}[5m])
          > (1 * 0.990000)
        )
      )
      and on(environment,tier,type,stage)
      (
        sum by(environment,tier,type,stage) (
          last_over_time(operation:rate_3d{monitor="global",type="web"}[5m])
        ) >= 0.00023
      )
    |||,
  },

})
