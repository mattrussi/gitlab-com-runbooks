local multiburn_factors = import './multiburn_factors.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local errorRateTermWithFixedThreshold(
  metric,
  metricSelectorHash,
  comparator,
  burnrate,
  thresholdSLOValue
      ) =  // For an error rate, this is usually close to 0
  |||
    %(metric)s{%(metricSelector)s}
    %(comparator)s (%(burnrate)g * %(thresholdSLOValue)f)
  ||| % {
    metric: metric,
    burnrate: burnrate,
    metricSelector: selectors.serializeHash(metricSelectorHash),
    thresholdSLOValue: thresholdSLOValue,
    comparator: comparator,
  };

local errorRateTermWithMetricSLO(
  metric,
  metricSelectorHash,
  comparator,
  burnrate,
  thresholdSLOMetricName,
  sloMetricSelectorHash,
  thresholdSLOMetricAggregationLabels,
      ) =
  |||
    %(metric)s{%(metricSelector)s}
    %(comparator)s on(%(thresholdSLOMetricAggregationLabels)s) group_left()
    (
      %(burnrate)g * (
        avg by (%(thresholdSLOMetricAggregationLabels)s) (%(thresholdSLOMetricName)s{%(sloSelector)s})
      )
    )
  ||| % {
    metric: metric,
    burnrate: burnrate,
    metricSelector: selectors.serializeHash(metricSelectorHash),
    thresholdSLOMetricName: thresholdSLOMetricName,
    sloSelector: selectors.serializeHash(sloMetricSelectorHash),
    thresholdSLOMetricAggregationLabels: aggregations.serialize(thresholdSLOMetricAggregationLabels),
    comparator: comparator,
  };

local apdexRateTermWithFixedThreshold(
  metric,
  metricSelectorHash,
  comparator,
  burnrate,
  thresholdSLOValue
      ) =  // For an apdex this is usually close to 1
  |||
    %(metric)s{%(metricSelector)s}
    %(comparator)s (1 - %(burnrate)g * %(inverseThresholdSLOValue)f)
  ||| % {
    metric: metric,
    burnrate: burnrate,
    metricSelector: selectors.serializeHash(metricSelectorHash),
    comparator: comparator,
    inverseThresholdSLOValue: 1 - thresholdSLOValue,
  };


local apdexRateTermWithMetricSLO(
  metric,
  metricSelectorHash,
  comparator,
  burnrate,
  thresholdSLOMetricName,
  sloMetricSelectorHash,
  thresholdSLOMetricAggregationLabels,
      ) =
  |||
    %(metric)s{%(metricSelector)s}
    %(comparator)s on(%(thresholdSLOMetricAggregationLabels)s) group_left()
    (
      1 -
      (
        %(burnrate)g * (1 - avg by (%(thresholdSLOMetricAggregationLabels)s) (%(thresholdSLOMetricName)s{%(sloSelector)s}))
      )
    )
  ||| % {
    metric: metric,
    burnrate: burnrate,
    metricSelector: selectors.serializeHash(metricSelectorHash),
    thresholdSLOMetricName: thresholdSLOMetricName,
    sloSelector: selectors.serializeHash(sloMetricSelectorHash),
    thresholdSLOMetricAggregationLabels: aggregations.serialize(thresholdSLOMetricAggregationLabels),
    comparator: comparator,
  };

local operationRateFilter(
  expression,
  operationRateMetric,
  operationRateAggregationLabels,
  operationRateSelectorHash,
  minimumOperationRateForMonitoring
      ) =
  if minimumOperationRateForMonitoring == null then
    expression
  else
    |||
      (
        %(expression)s
      )
      and on(%(operationRateAggregationLabels)s)
      (
        sum by(%(operationRateAggregationLabels)s) (%(operationRateMetric)s{%(operationRateSelector)s}) >= %(minimumOperationRateForMonitoring)g
      )
    ||| % {
      expression: strings.indent(expression, 2),
      operationRateMetric: operationRateMetric,
      minimumOperationRateForMonitoring: minimumOperationRateForMonitoring,
      operationRateSelector: selectors.serializeHash(operationRateSelectorHash),
      operationRateAggregationLabels: aggregations.serialize(operationRateAggregationLabels),
    };

{
  // Generates a multi-window, multi-burn-rate error expression
  multiburnRateErrorExpression(
    aggregationSet,
    metricSelectorHash,  // Selectors for the error rate metrics
    thresholdSLOMetricName=null,  // SLO metric name
    thresholdSLOMetricAggregationLabels=null,  // Labels to join the SLO metric to the error rate metrics with
    minimumOperationRateForMonitoring=null,  // minium operation rate vaue (in request-per-second)
    thresholdSLOValue=null,  // Error budget float value (between 0 and 1)
  )::
    local mergedMetricSelectors = selectors.merge(aggregationSet.selector, metricSelectorHash);
    local term(metric, burnrate) =
      if thresholdSLOMetricName != null then
        errorRateTermWithMetricSLO(
          metric=metric,
          metricSelectorHash=mergedMetricSelectors,
          comparator='>',
          burnrate=burnrate,
          thresholdSLOMetricName=thresholdSLOMetricName,
          sloMetricSelectorHash=aggregationSet.selector,
          thresholdSLOMetricAggregationLabels=thresholdSLOMetricAggregationLabels,
        )
      else
        errorRateTermWithFixedThreshold(
          metric=metric,
          metricSelectorHash=mergedMetricSelectors,
          comparator='>',
          burnrate=burnrate,
          thresholdSLOValue=thresholdSLOValue
        );

    local metric1h = aggregationSet.getErrorRatioMetricForBurnRate('1h', required=true);
    local metric5m = aggregationSet.getErrorRatioMetricForBurnRate('5m', required=true);
    local metric6h = aggregationSet.getErrorRatioMetricForBurnRate('6h', required=true);
    local metric30m = aggregationSet.getErrorRatioMetricForBurnRate('30m', required=true);

    local term_1h = term(metric1h, multiburn_factors.burnrate_1h);
    local term_5m = term(metric5m, multiburn_factors.burnrate_1h);
    local term_6h = term(metric6h, multiburn_factors.burnrate_6h);
    local term_30m = term(metric30m, multiburn_factors.burnrate_6h);

    local preOperationRateExpr = |||
      (
        %(term_1h)s
      )
      and
      (
        %(term_5m)s
      )
      or
      (
        %(term_6h)s
      )
      and
      (
        %(term_30m)s
      )
    ||| % {
      term_1h: strings.indent(term_1h, 2),
      term_5m: strings.indent(term_5m, 2),
      term_6h: strings.indent(term_6h, 2),
      term_30m: strings.indent(term_30m, 2),
    };

    operationRateFilter(
      preOperationRateExpr,
      aggregationSet.getOpsRateMetricForBurnRate('1h', required=true),
      aggregationSet.labels,
      mergedMetricSelectors,
      minimumOperationRateForMonitoring
    ),

  // Generates a multi-window, multi-burn-rate apdex score expression
  multiburnRateApdexExpression(
    aggregationSet,
    metricSelectorHash,  // Selectors for the error rate metrics
    thresholdSLOMetricName=null,  // SLO metric name
    thresholdSLOMetricAggregationLabels=null,  // Labels to join the SLO metric to the error rate metrics with
    minimumOperationRateForMonitoring=null,  // minium operation rate vaue (in request-per-second)
    thresholdSLOValue=null  // Error budget float value (between 0 and 1)
  )::
    local mergedMetricSelectors = selectors.merge(aggregationSet.selector, metricSelectorHash);
    local term(metric, burnrate) =
      if thresholdSLOMetricName != null then
        apdexRateTermWithMetricSLO(
          metric=metric,
          metricSelectorHash=mergedMetricSelectors,
          comparator='<',
          burnrate=burnrate,
          thresholdSLOMetricName=thresholdSLOMetricName,
          sloMetricSelectorHash=aggregationSet.selector,
          thresholdSLOMetricAggregationLabels=thresholdSLOMetricAggregationLabels,
        )
      else
        apdexRateTermWithFixedThreshold(
          metric=metric,
          metricSelectorHash=mergedMetricSelectors,
          comparator='<',
          burnrate=burnrate,
          thresholdSLOValue=thresholdSLOValue,
        );

    local metric1h = aggregationSet.getApdexRatioMetricForBurnRate('1h', required=true);
    local metric5m = aggregationSet.getApdexRatioMetricForBurnRate('5m', required=true);
    local metric6h = aggregationSet.getApdexRatioMetricForBurnRate('6h', required=true);
    local metric30m = aggregationSet.getApdexRatioMetricForBurnRate('30m', required=true);

    local term_1h = term(metric1h, multiburn_factors.burnrate_1h);
    local term_5m = term(metric5m, multiburn_factors.burnrate_1h);
    local term_6h = term(metric6h, multiburn_factors.burnrate_6h);
    local term_30m = term(metric30m, multiburn_factors.burnrate_6h);

    local preOperationRateExpr = |||
      (
        %(term_1h)s
      )
      and
      (
        %(term_5m)s
      )
      or
      (
        %(term_6h)s
      )
      and
      (
        %(term_30m)s
      )
    ||| % {
      term_1h: strings.indent(term_1h, 2),
      term_5m: strings.indent(term_5m, 2),
      term_6h: strings.indent(term_6h, 2),
      term_30m: strings.indent(term_30m, 2),
    };

    operationRateFilter(
      preOperationRateExpr,
      aggregationSet.getOpsRateMetricForBurnRate('1h', required=true),
      aggregationSet.labels,
      mergedMetricSelectors,
      minimumOperationRateForMonitoring
    ),

  errorHealthExpression(
    aggregationSet,
    metricSelectorHash,  // Selectors for the error rate metrics
    thresholdSLOMetricName,  // SLO metric name
    thresholdSLOMetricAggregationLabels,  // Labels to join the SLO metric to the error rate metrics with
  )::
    local mergedMetricSelectors = selectors.merge(aggregationSet.selector, metricSelectorHash);
    local term(metric, burnrate) =
      errorRateTermWithMetricSLO(
        metric=metric,
        metricSelectorHash=mergedMetricSelectors,
        comparator='> bool',
        burnrate=burnrate,
        thresholdSLOMetricName=thresholdSLOMetricName,
        sloMetricSelectorHash=aggregationSet.selector,
        thresholdSLOMetricAggregationLabels=thresholdSLOMetricAggregationLabels,
      );

    local metric1h = aggregationSet.getErrorRatioMetricForBurnRate('1h', required=true);
    local metric5m = aggregationSet.getErrorRatioMetricForBurnRate('5m', required=true);
    local metric6h = aggregationSet.getErrorRatioMetricForBurnRate('6h', required=true);
    local metric30m = aggregationSet.getErrorRatioMetricForBurnRate('30m', required=true);

    local term_1h = term(metric1h, multiburn_factors.burnrate_1h);
    local term_5m = term(metric5m, multiburn_factors.burnrate_1h);
    local term_6h = term(metric6h, multiburn_factors.burnrate_6h);
    local term_30m = term(metric30m, multiburn_factors.burnrate_6h);

    // Prometheus doesn't have boolean AND/OR/NOT operators, only vector label matching versions of these operators.
    // As a cheap trick workaround, we substitute * with `boolean and` and `clamp_max(.. + .., 1) for  `boolean or`.
    // Why this works: Assuming x,y are both either 1 or 0.
    // * `x AND y` is equivalent to `x * y`
    // * `x OR y` is equivalent to `clamp_max(x + y, 1)`
    // * `NOT x` is equivalent to `x == bool 0`
    |||
      clamp_max(
        (
          %(term_1h)s
        )
        *
        (
          %(term_5m)s
        )
        +
        (
          %(term_6h)s
        )
        *
        (
          %(term_30m)s
        ),
        1
      ) == bool 0
    ||| % {
      term_1h: strings.indent(term_1h, 4),
      term_5m: strings.indent(term_5m, 4),
      term_6h: strings.indent(term_6h, 4),
      term_30m: strings.indent(term_30m, 4),
    },

  apdexHealthExpression(
    aggregationSet,
    metricSelectorHash,  // Selectors for the error rate metrics
    thresholdSLOMetricName,  // SLO metric name
    thresholdSLOMetricAggregationLabels,  // Labels to join the SLO metric to the error rate metrics with
  )::
    local mergedMetricSelectors = selectors.merge(aggregationSet.selector, metricSelectorHash);
    local term(metric, burnrate) =
      apdexRateTermWithMetricSLO(
        metric=metric,
        metricSelectorHash=mergedMetricSelectors,
        comparator='< bool',
        burnrate=burnrate,
        thresholdSLOMetricName=thresholdSLOMetricName,
        sloMetricSelectorHash=aggregationSet.selector,
        thresholdSLOMetricAggregationLabels=thresholdSLOMetricAggregationLabels,
      );

    local metric1h = aggregationSet.getApdexRatioMetricForBurnRate('1h', required=true);
    local metric5m = aggregationSet.getApdexRatioMetricForBurnRate('5m', required=true);
    local metric6h = aggregationSet.getApdexRatioMetricForBurnRate('6h', required=true);
    local metric30m = aggregationSet.getApdexRatioMetricForBurnRate('30m', required=true);

    local term_1h = term(metric1h, multiburn_factors.burnrate_1h);
    local term_5m = term(metric5m, multiburn_factors.burnrate_1h);
    local term_6h = term(metric6h, multiburn_factors.burnrate_6h);
    local term_30m = term(metric30m, multiburn_factors.burnrate_6h);

    // Prometheus doesn't have boolean AND/OR/NOT operators, only vector label matching versions of these operators.
    // As a cheap trick workaround, we substitute * with `boolean and` and `clamp_max(.. + .., 1) for  `boolean or`.
    // Why this works: Assuming x,y are both either 1 or 0.
    // * `x AND y` is equivalent to `x * y`
    // * `x OR y` is equivalent to `clamp_max(x + y, 1)`
    // * `NOT x` is equivalent to `x == bool 0`
    |||
      clamp_max(
        (
          %(term_1h)s
        )
        *
        (
          %(term_5m)s
        )
        +
        (
          %(term_6h)s
        )
        *
        (
          %(term_30m)s
        ),
        1
      ) == bool 0
    ||| % {
      term_1h: strings.indent(term_1h, 4),
      term_5m: strings.indent(term_5m, 4),
      term_6h: strings.indent(term_6h, 4),
      term_30m: strings.indent(term_30m, 4),
    },
}
