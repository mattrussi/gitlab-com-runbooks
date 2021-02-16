local expression = import './expression.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local aggregationSets = import 'servicemetrics/aggregation-set.libsonnet';

local testAggregationSet = aggregationSets.AggregationSet({
  name: 'Test',
  selector: { monitor: 'global' },  // Not Thanos Ruler
  labels: ['environment', 'type', 'stage'],
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
  },
});


test.suite({
  testErrorBurnWithoutMinimumRate: {
    actual: expression.multiburnRateErrorExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      thresholdSLOMetricName='sla:error:rate',
      thresholdSLOMetricAggregationLabels=['type'],
    ),
    expect: |||
      (
        error:ratio_1h{monitor="global",type="web"}
        > on(type) group_left()
        (
          14.4 * (
            avg by (type) (sla:error:rate{monitor="global"})
          )
        )
      )
      and
      (
        error:ratio_5m{monitor="global",type="web"}
        > on(type) group_left()
        (
          14.4 * (
            avg by (type) (sla:error:rate{monitor="global"})
          )
        )
      )
      or
      (
        error:ratio_6h{monitor="global",type="web"}
        > on(type) group_left()
        (
          6 * (
            avg by (type) (sla:error:rate{monitor="global"})
          )
        )
      )
      and
      (
        error:ratio_30m{monitor="global",type="web"}
        > on(type) group_left()
        (
          6 * (
            avg by (type) (sla:error:rate{monitor="global"})
          )
        )
      )
    |||,
  },

  testErrorBurnWithMinimumRate: {
    actual: expression.multiburnRateErrorExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      thresholdSLOMetricName='sla:error:rate',
      thresholdSLOMetricAggregationLabels=['type'],
      minimumOperationRateForMonitoring=1,
    ),
    expect: |||
      (
        (
          error:ratio_1h{monitor="global",type="web"}
          > on(type) group_left()
          (
            14.4 * (
              avg by (type) (sla:error:rate{monitor="global"})
            )
          )
        )
        and
        (
          error:ratio_5m{monitor="global",type="web"}
          > on(type) group_left()
          (
            14.4 * (
              avg by (type) (sla:error:rate{monitor="global"})
            )
          )
        )
        or
        (
          error:ratio_6h{monitor="global",type="web"}
          > on(type) group_left()
          (
            6 * (
              avg by (type) (sla:error:rate{monitor="global"})
            )
          )
        )
        and
        (
          error:ratio_30m{monitor="global",type="web"}
          > on(type) group_left()
          (
            6 * (
              avg by (type) (sla:error:rate{monitor="global"})
            )
          )
        )
      )
      and on(environment,type,stage)
      (
        sum by(environment,type,stage) (operation:rate_1h{monitor="global",type="web"}) >= 1
      )
    |||,
  },


  testErrorBurnWithThreshold: {
    actual: expression.multiburnRateErrorExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      minimumOperationRateForMonitoring=1,
      thresholdSLOValue=0.01,
    ),
    expect: |||
      (
        (
          error:ratio_1h{monitor="global",type="web"}
          > (14.4 * 0.010000)
        )
        and
        (
          error:ratio_5m{monitor="global",type="web"}
          > (14.4 * 0.010000)
        )
        or
        (
          error:ratio_6h{monitor="global",type="web"}
          > (6 * 0.010000)
        )
        and
        (
          error:ratio_30m{monitor="global",type="web"}
          > (6 * 0.010000)
        )
      )
      and on(environment,type,stage)
      (
        sum by(environment,type,stage) (operation:rate_1h{monitor="global",type="web"}) >= 1
      )
    |||,
  },

  testApdexBurnWithoutMinimumRate: {
    actual: expression.multiburnRateApdexExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      thresholdSLOMetricName='sla:apdex:rate',
      thresholdSLOMetricAggregationLabels=['type'],
    ),
    expect: |||
      (
        apdex:ratio_1h{monitor="global",type="web"}
        < on(type) group_left()
        (
          1 -
          (
            14.4 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
          )
        )
      )
      and
      (
        apdex:ratio_5m{monitor="global",type="web"}
        < on(type) group_left()
        (
          1 -
          (
            14.4 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
          )
        )
      )
      or
      (
        apdex:ratio_6h{monitor="global",type="web"}
        < on(type) group_left()
        (
          1 -
          (
            6 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
          )
        )
      )
      and
      (
        apdex:ratio_30m{monitor="global",type="web"}
        < on(type) group_left()
        (
          1 -
          (
            6 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
          )
        )
      )
    |||,
  },

  testApdexBurnWithThreshold: {
    actual: expression.multiburnRateApdexExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      thresholdSLOValue=0.9995,
    ),
    expect: |||
      (
        apdex:ratio_1h{monitor="global",type="web"}
        < (1 - 14.4 * 0.000500)
      )
      and
      (
        apdex:ratio_5m{monitor="global",type="web"}
        < (1 - 14.4 * 0.000500)
      )
      or
      (
        apdex:ratio_6h{monitor="global",type="web"}
        < (1 - 6 * 0.000500)
      )
      and
      (
        apdex:ratio_30m{monitor="global",type="web"}
        < (1 - 6 * 0.000500)
      )
    |||,
  },

  testApdexBurnWithMinimumRate: {
    actual: expression.multiburnRateApdexExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      thresholdSLOMetricName='sla:apdex:rate',
      thresholdSLOMetricAggregationLabels=['type'],
      minimumOperationRateForMonitoring=1,
    ),
    expect: |||
      (
        (
          apdex:ratio_1h{monitor="global",type="web"}
          < on(type) group_left()
          (
            1 -
            (
              14.4 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        and
        (
          apdex:ratio_5m{monitor="global",type="web"}
          < on(type) group_left()
          (
            1 -
            (
              14.4 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        or
        (
          apdex:ratio_6h{monitor="global",type="web"}
          < on(type) group_left()
          (
            1 -
            (
              6 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        and
        (
          apdex:ratio_30m{monitor="global",type="web"}
          < on(type) group_left()
          (
            1 -
            (
              6 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
      )
      and on(environment,type,stage)
      (
        sum by(environment,type,stage) (operation:rate_1h{monitor="global",type="web"}) >= 1
      )
    |||,
  },

  testApdexBurnWithMinimumRateAndAggregation: {
    actual: expression.multiburnRateApdexExpression(
      aggregationSet=testAggregationSet,
      metricSelectorHash={ type: 'web' },
      thresholdSLOMetricName='sla:apdex:rate',
      thresholdSLOMetricAggregationLabels=['type'],
      minimumOperationRateForMonitoring=1
    ),
    expect: |||
      (
        (
          apdex:ratio_1h{monitor="global",type="web"}
          < on(type) group_left()
          (
            1 -
            (
              14.4 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        and
        (
          apdex:ratio_5m{monitor="global",type="web"}
          < on(type) group_left()
          (
            1 -
            (
              14.4 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        or
        (
          apdex:ratio_6h{monitor="global",type="web"}
          < on(type) group_left()
          (
            1 -
            (
              6 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        and
        (
          apdex:ratio_30m{monitor="global",type="web"}
          < on(type) group_left()
          (
            1 -
            (
              6 * (1 - avg by (type) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
      )
      and on(environment,type,stage)
      (
        sum by(environment,type,stage) (operation:rate_1h{monitor="global",type="web"}) >= 1
      )
    |||,
  },
})
