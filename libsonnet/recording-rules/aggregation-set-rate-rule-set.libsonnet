local helpers = import './helpers.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local errorRateVisitor = {
  metricName(aggregationSet, burnRate, required=false)::
    aggregationSet.getErrorRateMetricForBurnRate(burnRate, required),

  upscalingExpression(sourceAggregationSet, targetAggregationSet, burnRate)::
    helpers.upscaledErrorRateExpression(sourceAggregationSet, targetAggregationSet, burnRate),
};

local opsRateVisitor = {
  metricName(aggregationSet, burnRate, required=false)::
    aggregationSet.getOpsRateMetricForBurnRate(burnRate, required),

  upscalingExpression(sourceAggregationSet, targetAggregationSet, burnRate)::
    helpers.upscaledOpsRateExpression(sourceAggregationSet, targetAggregationSet, burnRate),
};

local getDirectRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, required, visitor) =
  local sourceMetricName = visitor.metricName(sourceAggregationSet, burnRate, required);
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

// Generates a rate expression, either as a direct aggregation from the source, or
// an upscaling expression, or a combination of the two
local getRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, visitor) =
  local upscaledExpr = visitor.upscalingExpression(sourceAggregationSet, targetAggregationSet, burnRate);

  // For 6h burn rate, we'll use either a combination of upscaling and direct aggregation,
  // or, if the source aggregations, don't exist, only use the upscaled metric
  if burnRate == '6h' then
    local directExpr = getDirectRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, required=false, visitor=visitor);

    if directExpr != null then
      |||
        (
          %(directExpr)s
        )
        or
        (
          %(upscaledExpr)s
        )
      ||| % {
        directExpr: strings.indent(directExpr, 2),
        upscaledExpr: strings.indent(upscaledExpr, 2),
      }
    else
      // If we there is no source burnRate, use only upscaling
      upscaledExpr

  else if burnRate == '3d' then
    // For 3d expressions, we always use upscaling
    upscaledExpr
  else
    // In all other cases, we use the direct expression and raise an exception if the source burn rates do not exist
    getDirectRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, required=true, visitor=visitor);

// Generates the recording rule YAML when required. Returns an array of 0 or more definitions
local getRecordingRuleDefinitions(sourceAggregationSet, targetAggregationSet, burnRate, visitor) =
  local targetMetric = visitor.metricName(targetAggregationSet, burnRate, required=false);

  if targetMetric == null then
    []
  else
    [{
      record: targetMetric,
      expr: getRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, visitor),
    }];

{
  /** Aggregates Ops Rates and Error Rates between aggregation sets  */
  aggregationSetRateRuleSet(sourceAggregationSet, targetAggregationSet, burnRate)::
    getRecordingRuleDefinitions(sourceAggregationSet, targetAggregationSet, burnRate, errorRateVisitor)
    +
    getRecordingRuleDefinitions(sourceAggregationSet, targetAggregationSet, burnRate, opsRateVisitor),
}
