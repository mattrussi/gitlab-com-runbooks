local helpers = import './helpers.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local getDirectRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, visitor) =
  local sourceMetricName = visitor.metricName(sourceAggregationSet, burnRate, required=false);
  local targetAggregationLabels = aggregations.serialize(targetAggregationSet.labels);
  local sourceSelector = selectors.serializeHash(sourceAggregationSet.selector);

  if sourceMetricName != null then
    |||
      sum by (%(targetAggregationLabels)s) (
        (%(sourceMetricName)s{%(sourceSelector)s} >= 0)%(aggregationFilterExpr)s
      )
    ||| % {
      sourceMetricName: sourceMetricName,
      targetAggregationLabels: targetAggregationLabels,
      sourceSelector: sourceSelector,
      aggregationFilterExpr: helpers.aggregationFilterExpr(targetAggregationSet),
    }
  else null;

local getErrorSourcedSuccessRateExpression(source, target, burnRate, errorVisitor, opsVisitor) =
  local sourceErrorRateMetricName = errorVisitor.metricName(source, burnRate);
  local sourceOpsRateMetricName = opsVisitor.metricName(source, burnRate);
  local targetAggregationLabels = aggregations.serialize(target.labels);
  local sourceSelector = selectors.serializeHash(source.selector);
  if sourceErrorRateMetricName != null && sourceOpsRateMetricName != null then
    |||
      sum by (%(targetAggregationLabels)s) (
        (
          %(opsRateMetricName)s{%(sourceSelector)s}
          -
          %(errorRate)s
        )%(aggregationFilterExpr)s
      )
    ||| % {
      targetAggregationLabels: targetAggregationLabels,
      opsRateMetricName: sourceOpsRateMetricName,
      errorRate: strings.chomp(helpers.errorRateWithFallbackPromExpression(source, burnRate)),
      sourceSelector: sourceSelector,
      aggregationFilterExpr: helpers.aggregationFilterExpr(target),
    }
  else null;

local errorRateVisitor = {
  metricName(aggregationSet, burnRate, required=false)::
    aggregationSet.getErrorRateMetricForBurnRate(burnRate, required),

  getRateExpression(sourceAggregationSet, targetAggregationSet, burnRate)::
    local directExpr = getDirectRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, self);
    helpers.combinedErrorRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, directExpr),
};

local opsRateVisitor = {
  metricName(aggregationSet, burnRate, required=false)::
    aggregationSet.getOpsRateMetricForBurnRate(burnRate, required),

  getRateExpression(sourceAggregationSet, targetAggregationSet, burnRate)::
    local directExpr = getDirectRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, self);
    helpers.combinedOpsRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, directExpr),
};

local getSuccessRateExpression(source, target, burnRate, successRateVisitor) =
  local sourceSuccessRateMetric = successRateVisitor.metricName(source, burnRate);
  if sourceSuccessRateMetric != null then
    getDirectRateExpression(source, target, burnRate, successRateVisitor)
  else
    getErrorSourcedSuccessRateExpression(source, target, burnRate, errorRateVisitor, opsRateVisitor);

local successRateVisitor = {
  metricName(aggregationSet, burnRate, required=false)::
    aggregationSet.getSuccessRateMetricForBurnRate(burnRate, required),

  getRateExpression(source, target, burnRate)::
    local expression = getSuccessRateExpression(source, target, burnRate, self);
    helpers.combinedSuccessRateExpression(source, target, burnRate, expression),
};

// Generates the recording rule YAML when required. Returns an array of 0 or more definitions
local getRecordingRuleDefinitions(sourceAggregationSet, targetAggregationSet, burnRate, visitor) =
  local targetMetric = visitor.metricName(targetAggregationSet, burnRate, required=false);

  if targetMetric == null then
    []
  else
    [{
      record: targetMetric,
      expr: visitor.getRateExpression(sourceAggregationSet, targetAggregationSet, burnRate),
    }];

{
  /** Aggregates Ops Rates and Error Rates between aggregation sets  */
  aggregationSetRateRuleSet(sourceAggregationSet, targetAggregationSet, burnRate)::
    getRecordingRuleDefinitions(sourceAggregationSet, targetAggregationSet, burnRate, errorRateVisitor)
    +
    getRecordingRuleDefinitions(sourceAggregationSet, targetAggregationSet, burnRate, opsRateVisitor)
    +
    getRecordingRuleDefinitions(sourceAggregationSet, targetAggregationSet, burnRate, successRateVisitor),
}
