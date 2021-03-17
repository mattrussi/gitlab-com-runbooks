local helpers = import './helpers.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

{
  /** Aggregates Ops Rates and Error Rates between aggregation sets  */
  aggregationSetRateRuleSet(sourceAggregationSet, targetAggregationSet, burnRate)::
    local sourceOpsRateMetric = sourceAggregationSet.getOpsRateMetricForBurnRate(burnRate);
    local sourceErrorRateMetric = sourceAggregationSet.getErrorRateMetricForBurnRate(burnRate);
    local targetOpsRateMetric = targetAggregationSet.getOpsRateMetricForBurnRate(burnRate);
    local targetErrorRateMetric = targetAggregationSet.getErrorRateMetricForBurnRate(burnRate);

    local targetAggregationLabels = aggregations.serialize(targetAggregationSet.labels);
    local sourceSelector = selectors.serializeHash(sourceAggregationSet.selector);

    local formatConfig = {
      sourceOpsRateMetric: sourceOpsRateMetric,
      sourceErrorRateMetric: sourceErrorRateMetric,
      targetOpsRateMetric: targetOpsRateMetric,
      targetErrorRateMetric: targetErrorRateMetric,
      targetAggregationLabels: targetAggregationLabels,
      sourceSelector: sourceSelector,
      aggregationFilterExpr: helpers.aggregationFilterExpr(targetAggregationSet),
    };

    (
      if sourceErrorRateMetric == null || targetErrorRateMetric == null then
        []
      else
        [{
          record: targetErrorRateMetric,
          expr: |||
            sum by (%(targetAggregationLabels)s) (
              %(sourceErrorRateMetric)s{%(sourceSelector)s} >= 0%(aggregationFilterExpr)s
            )
          ||| % formatConfig,
        }]
    )
    +
    (
      if sourceOpsRateMetric == null || targetOpsRateMetric == null then
        []
      else
        [{
          record: targetOpsRateMetric,
          expr: |||
            sum by (%(targetAggregationLabels)s) (
              %(sourceOpsRateMetric)s{%(sourceSelector)s} >= 0%(aggregationFilterExpr)s
            )
          ||| % formatConfig,
        }]
    ),
}
