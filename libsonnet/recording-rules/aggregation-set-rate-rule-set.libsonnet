local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local aggregationFilterExpr = import 'recording-rules/lib/aggregation-filter-expr.libsonnet';
local optionalOffset = import 'recording-rules/lib/optional-offset.libsonnet';
local upscaling = import 'recording-rules/lib/upscaling.libsonnet';
local strings = import 'utils/strings.libsonnet';

local getDirectRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, visitor) =
  local sourceMetricName = visitor.metricName(sourceAggregationSet, burnRate, required=false);
  local targetAggregationLabels = aggregations.serialize(targetAggregationSet.labels);
  local sourceSelector = selectors.serializeHash(sourceAggregationSet.selector);

  if sourceMetricName != null then
    |||
      sum by (%(targetAggregationLabels)s) (
        (%(sourceMetricName)s{%(sourceSelector)s}%(optionalOffset)s >= 0)%(aggregationFilterExpr)s
      )
    ||| % {
      sourceMetricName: sourceMetricName,
      targetAggregationLabels: targetAggregationLabels,
      sourceSelector: sourceSelector,
      aggregationFilterExpr: aggregationFilterExpr(targetAggregationSet),
      optionalOffset: optionalOffset(targetAggregationSet.offset),
    }
  else null;

local errorRateVisitor = {
  metricName(aggregationSet, burnRate, required=false)::
    aggregationSet.getErrorRateMetricForBurnRate(burnRate, required),

  getRateExpression(sourceAggregationSet, targetAggregationSet, burnRate)::
    local directExpr = getDirectRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, self);
    upscaling.combinedErrorRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, directExpr),
};

local opsRateVisitor = {
  metricName(aggregationSet, burnRate, required=false)::
    aggregationSet.getOpsRateMetricForBurnRate(burnRate, required),

  getRateExpression(sourceAggregationSet, targetAggregationSet, burnRate)::
    local directExpr = getDirectRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, self);
    upscaling.combinedOpsRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, directExpr),
};

// Generates the recording rule YAML when required. Returns an array of 0 or more definitions
local getRecordingRuleDefinitions(sourceAggregationSet, targetAggregationSet, burnRate, visitor) =
  local targetMetric = visitor.metricName(targetAggregationSet, burnRate, required=false);

  if targetMetric == null then
    []
  else
    [
      std.prune(
        {
          record: targetMetric,
          labels: targetAggregationSet.recordingRuleStaticLabels,
          expr: visitor.getRateExpression(sourceAggregationSet, targetAggregationSet, burnRate),
        },
      ),
    ];

{
  /** Aggregates Ops Rates and Error Rates between aggregation sets  */
  aggregationSetRateRuleSet(sourceAggregationSet, targetAggregationSet, burnRate)::
    getRecordingRuleDefinitions(sourceAggregationSet, targetAggregationSet, burnRate, errorRateVisitor)
    +
    getRecordingRuleDefinitions(sourceAggregationSet, targetAggregationSet, burnRate, opsRateVisitor),
}
