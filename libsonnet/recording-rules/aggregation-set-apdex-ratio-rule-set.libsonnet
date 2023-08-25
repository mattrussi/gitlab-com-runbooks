local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local aggregationFilterExpr = import 'recording-rules/lib/aggregation-filter-expr.libsonnet';
local upscaling = import 'recording-rules/lib/upscaling.libsonnet';
local strings = import 'utils/strings.libsonnet';

// Returns a direct apdex ratio transformation expression or null if one cannot be generated because the source
// does not contain the correct recording rules
local getDirectApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate) =
  local sourceApdexSuccessRateMetric = sourceAggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate, required=false);
  local sourceApdexWeightMetric = sourceAggregationSet.getApdexWeightMetricForBurnRate(burnRate, required=false);

  if sourceApdexSuccessRateMetric != null && sourceApdexWeightMetric != null then
    |||
      sum by (%(targetAggregationLabels)s) (
        (%(sourceApdexSuccessRateMetric)s{%(sourceSelector)s} >= 0)%(aggregationFilterExpr)s
      )
      /
      sum by (%(targetAggregationLabels)s) (
        (%(sourceApdexWeightMetric)s{%(sourceSelector)s} >= 0)%(aggregationFilterExpr)s
      )
    ||| % {
      targetAggregationLabels: aggregations.serialize(targetAggregationSet.labels),
      sourceSelector: selectors.serializeHash(sourceAggregationSet.selector),
      aggregationFilterExpr: aggregationFilterExpr(targetAggregationSet),
      sourceApdexSuccessRateMetric: sourceApdexSuccessRateMetric,
      sourceApdexWeightMetric: sourceApdexWeightMetric,
    }
  else null;

local getDirectRate(sourceAggregationSet, targetAggregationSet, burnRate, sourceMetric) =
  if sourceMetric != null then
    |||
      sum by (%(targetAggregationLabels)s) (
        (%(sourceMetric)s{%(sourceSelector)s} >= 0)%(aggregationFilterExpr)s
      )
    ||| % {
      targetAggregationLabels: aggregations.serialize(targetAggregationSet.labels),
      sourceSelector: selectors.serializeHash(sourceAggregationSet.selector),
      aggregationFilterExpr: aggregationFilterExpr(targetAggregationSet),
      sourceMetric: sourceMetric,
    }
  else null;

local getApdexSuccessRateTransformExpression(sourceAggregationSet, targetAggregationSet, burnRate) =
  local directExpr = getDirectRate(sourceAggregationSet, targetAggregationSet, burnRate, sourceMetric=sourceAggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate, required=false));
  upscaling.combinedApdexSuccessRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, directExpr);

local getApdexWeightTransformExpression(sourceAggregationSet, targetAggregationSet, burnRate) =
  local directExpr = getDirectRate(sourceAggregationSet, targetAggregationSet, burnRate, sourceMetric=sourceAggregationSet.getApdexWeightMetricForBurnRate(burnRate, required=false));
  upscaling.combinedApdexWeightExpression(sourceAggregationSet, targetAggregationSet, burnRate, directExpr);

local getApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate) =
  local directExpr = getDirectApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate);
  upscaling.combinedApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate, directExpr);

{
  // Aggregates apdex scores from one aggregation set to another. Intended to be used
  // for aggregating Prometheus metrics into Thanos global view
  aggregationSetApdexRatioRuleSet(sourceAggregationSet, targetAggregationSet, burnRate)::
    local targetApdexRatioMetric = targetAggregationSet.getApdexRatioMetricForBurnRate(burnRate);
    local targetApdexWeightMetric = targetAggregationSet.getApdexWeightMetricForBurnRate(burnRate);
    local targetApdexSuccessRateMetric = targetAggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate);

    local targetAggregationLabels = aggregations.serialize(targetAggregationSet.labels);
    local sourceSelector = selectors.serializeHash(sourceAggregationSet.selector);

    local formatConfig = {
      targetApdexRatioMetric: targetApdexRatioMetric,
      targetApdexWeightMetric: targetApdexWeightMetric,
      targetAggregationLabels: targetAggregationLabels,
      sourceSelector: sourceSelector,
      aggregationFilterExpr: aggregationFilterExpr(targetAggregationSet),
    };

    (
      if targetApdexWeightMetric == null then
        []
      else
        [
          std.prune({
            record: targetApdexWeightMetric,
            labels: targetAggregationSet.recordingRuleStaticLabels,
            expr: getApdexWeightTransformExpression(sourceAggregationSet, targetAggregationSet, burnRate),
          }),
        ]
    )
    +
    (
      if targetApdexSuccessRateMetric == null then
        []
      else
        [
          std.prune({
            record: targetApdexSuccessRateMetric,
            labels: targetAggregationSet.recordingRuleStaticLabels,
            expr: getApdexSuccessRateTransformExpression(sourceAggregationSet, targetAggregationSet, burnRate),
          }),
        ]
    )
    +
    (
      if targetApdexRatioMetric == null then
        []
      else
        [
          std.prune({
            record: targetApdexRatioMetric,
            labels: targetAggregationSet.recordingRuleStaticLabels,
            expr: getApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate),
          }),
        ]
    ),


}
