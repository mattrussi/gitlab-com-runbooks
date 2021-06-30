local multiburn_factors = import './multiburn_factors.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local joins = import 'promql/joins.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local generator = import 'slo_expression_generator.libsonnet';
local durationParser = import 'utils/duration-parser.libsonnet';
local strings = import 'utils/strings.libsonnet';

// Given minimumOperationRateForMonitoring xor minimumSamplesForMonitoring,
// returns an actual minimumOperationRateForMonitoring.
// For minimumSamplesForMonitoring, calculates what the minimum sample rate per second,
// over the longWindow needs to be.
local calculateMinimumOperationRateForMonitoring(
  operationRateWindowDuration,
  minimumOperationRateForMonitoring,
  minimumSamplesForMonitoring,
      ) =
  if minimumOperationRateForMonitoring == null && minimumSamplesForMonitoring == null then
    null
  else if minimumOperationRateForMonitoring != null && minimumSamplesForMonitoring != null then
    std.assertEqual('', { __assert: 'minimumOperationRateForMonitoring and minimumSamplesForMonitoring are exclusive. Please set at most one.' })
  else if minimumOperationRateForMonitoring != null then
    minimumOperationRateForMonitoring
  else
    minimumSamplesForMonitoring / durationParser.toSeconds(operationRateWindowDuration);

local operationRateFilter(
  expression,
  operationRateMetric,
  operationRateAggregationLabels,
  operationRateSelectorHash,
  operationRateWindowDuration,
  minimumOperationRateForMonitoring,
  minimumSamplesForMonitoring
      ) =

  local requiredOpRate = calculateMinimumOperationRateForMonitoring(
    operationRateWindowDuration=operationRateWindowDuration,
    minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
    minimumSamplesForMonitoring=minimumSamplesForMonitoring,
  );

  if requiredOpRate == null then
    expression
  else
    |||
      (
        %(expression)s
      )
      and on(%(operationRateAggregationLabels)s)
      (
        sum by(%(operationRateAggregationLabels)s) (%(operationRateMetric)s{%(operationRateSelector)s}) >= %(requiredOpRate)g
      )
    ||| % {
      expression: strings.indent(expression, 2),
      operationRateMetric: operationRateMetric,
      requiredOpRate: requiredOpRate,
      operationRateSelector: selectors.serializeHash(operationRateSelectorHash),
      operationRateAggregationLabels: aggregations.serialize(operationRateAggregationLabels),
    };

local clampMaxHealthExpression(expression) =
  |||
    clamp_max(
      %(expression)s,
      1
    ) == bool 0
  ||| % {
    expression: strings.indent(expression, 2),
  };

{
  // Generates a multi-window, multi-burn-rate error expression
  multiburnRateErrorExpression(
    aggregationSet,
    metricSelectorHash,  // Selectors for the error rate metrics
    windows=['1h', '6h'],  // Sets of windows in this SLO expression, identified by longWindow duration
    thresholdSLOValue,  // Error budget float value (between 0 and 1)
    minimumOperationRateForMonitoring=null,  // minium operation rate vaue (in request-per-second)
    minimumSamplesForMonitoring=null,  // minimum number of operations recorded, over the longWindow period, for monitoring
    operationRateWindowDuration='1h',  // Window over which to evaluate operation rate
  )::
    local mergedMetricSelectors = selectors.merge(aggregationSet.selector, metricSelectorHash);

    local preOperationRateExpr = generator.expressionGenerator(
      aggregationSet=aggregationSet,
      metricSelectorHash=metricSelectorHash,
      windows=windows,
      termGenerator=generator.termGenerators.fixed(thresholdValue=thresholdSLOValue),
      metricLookup=generator.metricLookups.errorRate(),
      isApdexExpression=false,
    );

    operationRateFilter(
      preOperationRateExpr,
      aggregationSet.getOpsRateMetricForBurnRate(operationRateWindowDuration, required=true),
      aggregationSet.labels,
      mergedMetricSelectors,
      operationRateWindowDuration=operationRateWindowDuration,
      minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
      minimumSamplesForMonitoring=minimumSamplesForMonitoring,
    ),

  // Generates a multi-window, multi-burn-rate apdex score expression
  multiburnRateApdexExpression(
    aggregationSet,
    metricSelectorHash,  // Selectors for the error rate metrics
    thresholdSLOValue,  // Error budget float value (between 0 and 1)
    windows=['1h', '6h'],  // Sets of windows in this SLO expression, identified by longWindow duration
    minimumOperationRateForMonitoring=null,  // minium operation rate vaue (in request-per-second)
    minimumSamplesForMonitoring=null,  // minimum number of operations recorded, over the longWindow period, for monitoring
    operationRateWindowDuration='1h',  // Window over which to evaluate operation rate
  )::
    local mergedMetricSelectors = selectors.merge(aggregationSet.selector, metricSelectorHash);

    local preOperationRateExpr = generator.expressionGenerator(
      aggregationSet=aggregationSet,
      metricSelectorHash=metricSelectorHash,
      windows=windows,
      termGenerator=generator.termGenerators.fixed(thresholdValue=thresholdSLOValue),
      metricLookup=generator.metricLookups.apdex(),
      isApdexExpression=true,
    );

    operationRateFilter(
      preOperationRateExpr,
      aggregationSet.getOpsRateMetricForBurnRate(operationRateWindowDuration, required=true),
      aggregationSet.labels,
      mergedMetricSelectors,
      operationRateWindowDuration=operationRateWindowDuration,
      minimumOperationRateForMonitoring=minimumOperationRateForMonitoring,
      minimumSamplesForMonitoring=minimumSamplesForMonitoring,
    ),

  errorHealthExpression(
    aggregationSet,
    metricSelectorHash,  // Selectors for the error rate metrics
    thresholdSLOMetricName,  // SLO metric name
    thresholdSLOMetricAggregationLabels,  // Labels to join the SLO metric to the error rate metrics with
  )::
    local termGenerator =
      generator.termGenerators.metricThreshold(
        thresholdSLOMetricAggregationLabels=thresholdSLOMetricAggregationLabels,
        thresholdSLOMetricName=thresholdSLOMetricName,
        sloSelector=aggregationSet.selector
      );

    local expression = generator.expressionGenerator(
      aggregationSet=aggregationSet,
      metricSelectorHash=metricSelectorHash,
      termGenerator=termGenerator,
      metricLookup=generator.metricLookups.errorRate(),
      isApdexExpression=false,

      // Prometheus doesn't have boolean AND/OR/NOT operators, only vector label matching versions of these operators.
      // As a cheap trick workaround, we substitute * with `boolean and` and `clamp_max(.. + .., 1) for  `boolean or`.
      // Why this works: Assuming x,y are both either 1 or 0.
      // * `x AND y` is equivalent to `x * y`
      // * `x OR y` is equivalent to `clamp_max(x + y, 1)`
      // * `NOT x` is equivalent to `x == bool 0`
      sloExpressionComparator='> bool',
      termJoinOperator='*',
      windowPairJoinOperator='+',
    );

    clampMaxHealthExpression(expression),

  apdexHealthExpression(
    aggregationSet,
    metricSelectorHash,  // Selectors for the error rate metrics
    thresholdSLOMetricName,  // SLO metric name
    thresholdSLOMetricAggregationLabels,  // Labels to join the SLO metric to the error rate metrics with
  )::
    local termGenerator =
      generator.termGenerators.metricThreshold(
        thresholdSLOMetricAggregationLabels=thresholdSLOMetricAggregationLabels,
        thresholdSLOMetricName=thresholdSLOMetricName,
        sloSelector=aggregationSet.selector
      );

    local expression = generator.expressionGenerator(
      aggregationSet=aggregationSet,
      metricSelectorHash=metricSelectorHash,
      termGenerator=termGenerator,
      metricLookup=generator.metricLookups.apdex(),
      isApdexExpression=true,

      // Prometheus doesn't have boolean AND/OR/NOT operators, only vector label matching versions of these operators.
      // As a cheap trick workaround, we substitute * with `boolean and` and `clamp_max(.. + .., 1) for  `boolean or`.
      // Why this works: Assuming x,y are both either 1 or 0.
      // * `x AND y` is equivalent to `x * y`
      // * `x OR y` is equivalent to `clamp_max(x + y, 1)`
      // * `NOT x` is equivalent to `x == bool 0`
      sloExpressionComparator='< bool',
      termJoinOperator='*',
      windowPairJoinOperator='+',
    );

    clampMaxHealthExpression(expression),
}
