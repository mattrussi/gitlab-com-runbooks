local helpers = import './helpers.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

{
  // Aggregates apdex scores from one aggregation set to another. Intended to be used
  // for aggregating Prometheus metrics into Thanos global view
  aggregationSetApdexRatioRuleSet(sourceAggregationSet, targetAggregationSet, burnRate)::
    local targetApdexRatioMetric = targetAggregationSet.getApdexRatioMetricForBurnRate(burnRate);
    local targetApdexWeightMetric = targetAggregationSet.getApdexWeightMetricForBurnRate(burnRate);

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
      if targetApdexRatioMetric == null then
        []
      else
        local sourceApdexSuccessRateMetric = sourceAggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate, required=true);
        local sourceApdexWeightMetric = sourceAggregationSet.getApdexWeightMetricForBurnRate(burnRate, required=true);
        local expr =
          |||
            sum by (%(targetAggregationLabels)s) (
              (%(sourceApdexSuccessRateMetric)s{%(sourceSelector)s} >= 0)%(aggregationFilterExpr)s
            )
            /
            sum by (%(targetAggregationLabels)s) (
              (%(sourceApdexWeightMetric)s{%(sourceSelector)s} >= 0)%(aggregationFilterExpr)s
            )
          ||| % formatConfig {
            sourceApdexSuccessRateMetric: sourceApdexSuccessRateMetric,
            sourceApdexWeightMetric: sourceApdexWeightMetric,
          };

        local upscaledExpr = helpers.upscaledApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate);

        [{
          record: targetApdexRatioMetric,
          expr:
            /**
             * For 6h burn rates for SLIs with `upscaleLongerBurnRates` set to true,
             * we may not have 6h apdex components, so for those we calculate the 6h metric
             * by upscaling 1h metrics
             */
            if burnRate == '6h' then
              |||
                (
                  %(expr)s
                )
                or
                (
                  %(upscaledExpr)s
                )
              ||| % {
                expr: strings.indent(expr, 2),
                upscaledExpr: strings.indent(upscaledExpr, 2),
              }
            else if burnRate == '3d' then
              upscaledExpr
            else
              expr,
        }]
    ),


}
