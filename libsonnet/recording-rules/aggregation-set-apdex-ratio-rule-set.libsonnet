local helpers = import './helpers.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

// Returns a direct apdex ratio expression, null if the source burn rate does not exist and required=false or
// an exception if the source burn rate does not exist, and required=true
local getDirectApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate, required) =
  local sourceApdexSuccessRateMetric = sourceAggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate, required=required);
  local sourceApdexWeightMetric = sourceAggregationSet.getApdexWeightMetricForBurnRate(burnRate, required=required);

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
      aggregationFilterExpr: helpers.aggregationFilterExpr(targetAggregationSet),
      sourceApdexSuccessRateMetric: sourceApdexSuccessRateMetric,
      sourceApdexWeightMetric: sourceApdexWeightMetric,
    }
  else null;

local getApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate) =
  local upscaledExpr = helpers.upscaledApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate);

  // For 6h burn rate, we'll use either a combination of upscaling and direct aggregation,
  // or, if the source aggregations, don't exist, only use the upscaled metric
  if burnRate == '6h' then
    local directExpr = getDirectApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate, required=false);

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
    // In all other cases, we use the direct expression and raise an exception if the source burn rates do no exist
    getDirectApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate, required=true);

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
      aggregationFilterExpr: helpers.aggregationFilterExpr(targetAggregationSet),
    };

    (
      if targetApdexWeightMetric == null then
        []
      else
        [{
          record: targetApdexWeightMetric,
          expr: |||
            sum by (%(targetAggregationLabels)s) (
              (%(sourceApdexWeightMetric)s{%(sourceSelector)s} >= 0)%(aggregationFilterExpr)s
            )
          ||| % formatConfig {
            sourceApdexWeightMetric: sourceAggregationSet.getApdexWeightMetricForBurnRate(burnRate, required=true),
          },
        }]
    )
    +
    (
      if targetApdexSuccessRateMetric == null then
        []
      else
        [{
          record: targetApdexSuccessRateMetric,
          expr: |||
            sum by (%(targetAggregationLabels)s) (
              (%(sourceApdexWeightMetric)s{%(sourceSelector)s} >= 0)%(aggregationFilterExpr)s
            )
          ||| % formatConfig {
            sourceApdexWeightMetric: sourceAggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate, required=true),
          },
        }]
    )
    +
    (
      if targetApdexRatioMetric == null then
        []
      else
        [{
          record: targetApdexRatioMetric,
          expr: getApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate),
        }]
    ),


}
