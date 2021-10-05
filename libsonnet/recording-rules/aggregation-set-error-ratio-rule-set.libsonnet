local helpers = import './helpers.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';


{
  aggregationSetErrorRatioRuleSet(sourceAggregationSet, targetAggregationSet, burnRate)::
    local targetErrorRatioMetric = targetAggregationSet.getErrorRatioMetricForBurnRate(burnRate);
    local targetOpsRateMetric = targetAggregationSet.getOpsRateMetricForBurnRate(burnRate);
    local targetErrorRateMetric = targetAggregationSet.getErrorRateMetricForBurnRate(burnRate);
    local targetAggregationLabels = aggregations.serialize(targetAggregationSet.labels);
    local sourceSelector = selectors.serializeHash(sourceAggregationSet.selector);

    local formatConfig = {
      burnRate: burnRate,
      targetOpsRateMetric: targetOpsRateMetric,
      targetErrorRateMetric: targetErrorRateMetric,
      targetSelector: selectors.serializeHash(targetAggregationSet.selector),
      targetAggregationLabels: targetAggregationLabels,
      sourceSelector: sourceSelector,
      aggregationFilterExpr: helpers.aggregationFilterExpr(targetAggregationSet),
    };

    if targetErrorRatioMetric == null then
      []
    else
      local errorRateExpr =
        if targetErrorRateMetric == null then
          local sourceErrorRateMetric = sourceAggregationSet.getErrorRateMetricForBurnRate(burnRate, required=true);
          |||
            sum by (%(targetAggregationLabels)s) (
              (%(sourceErrorRateMetric)s{%(sourceSelector)s} >= 0)%(aggregationFilterExpr)s
            )
          ||| % formatConfig {
            sourceErrorRateMetric: sourceErrorRateMetric,
          }
        else
          '%(targetErrorRateMetric)s{%(targetSelector)s}' % formatConfig;

      local opsRateExpr =
        if targetOpsRateMetric == null then
          local sourceOpsRateMetric = sourceAggregationSet.getOpsRateMetricForBurnRate(burnRate, required=true);
          |||
            sum by (%(targetAggregationLabels)s) (
              (%(sourceOpsRateMetric)s{%(sourceSelector)s} >= 0)%(aggregationFilterExpr)s
            )
          ||| % formatConfig {
            sourceOpsRateMetric: sourceOpsRateMetric,
          }
        else
          '%(targetOpsRateMetric)s{%(targetSelector)s}' % formatConfig;

      local directExpr = |||
        %(errorRateExpr)s
        /
        %(opsRateExpr)s
      ||| % {
        errorRateExpr: errorRateExpr,
        opsRateExpr: opsRateExpr,
      };

      [{
        record: targetErrorRatioMetric,
        expr: helpers.combinedErrorRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate, directExpr),
      }],
}
