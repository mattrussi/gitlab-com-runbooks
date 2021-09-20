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

      local expr = |||
        %(errorRateExpr)s
        /
        %(opsRateExpr)s
      ||| % {
        errorRateExpr: errorRateExpr,
        opsRateExpr: opsRateExpr,
      };

      local upscaledExpr = helpers.upscaledErrorRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate);

      [{
        record: targetErrorRatioMetric,
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
      }],
}
