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
    local aggregationFilter = targetAggregationSet.aggregationFilter;

    // For service level aggregations, we need to filter out any SLIs which we don't want to include
    // in the service level aggregation.
    // These are defined in the SLI with `aggregateToService:false`
    local aggregationFilterExpr =
      if aggregationFilter != null then
        ' and on(component, type) (gitlab_component_service:mapping{monitor="global", %(aggregationFilter)s_aggregation="yes"})' % {
          sourceSelector: sourceSelector,
          aggregationFilter: aggregationFilter,
        }
      else
        '';

    local formatConfig = {
      targetOpsRateMetric: targetOpsRateMetric,
      targetErrorRateMetric: targetErrorRateMetric,
      targetSelector: selectors.serializeHash(targetAggregationSet.selector),
      targetAggregationLabels: targetAggregationLabels,
      sourceSelector: sourceSelector,
      aggregationFilterExpr: aggregationFilterExpr,
    };

    if targetErrorRatioMetric == null then
      []
    else
      local errorRateExpr =
        if targetErrorRateMetric == null then
          local sourceErrorRateMetric = sourceAggregationSet.getErrorRateMetricForBurnRate(burnRate, required=true);
          |||
            sum by (%(targetAggregationLabels)s) (
              %(sourceErrorRateMetric)s{%(sourceSelector)s} >= 0%(aggregationFilterExpr)s
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
              %(sourceOpsRateMetric)s{%(sourceSelector)s} >= 0%(aggregationFilterExpr)s
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
                sum by (%(targetAggregationLabels)s) (
                  sum_over_time(%(sourceErrorRateMetric1h)s{%(sourceSelectorWithUpscale)s}[6h])%(aggregationFilterExpr)s
                )
                /
                sum by (%(targetAggregationLabels)s) (
                  sum_over_time(%(sourceApdexOpsRateMetric1h)s{%(sourceSelectorWithUpscale)s}[6h])%(aggregationFilterExpr)s
                )
              )
            ||| % formatConfig {
              expr: strings.indent(expr, 2),
              sourceErrorRateMetric1h: sourceAggregationSet.getErrorRateMetricForBurnRate('1h', required=true),
              sourceApdexOpsRateMetric1h: sourceAggregationSet.getOpsRateMetricForBurnRate('1h', required=true),
              sourceSelectorWithUpscale: selectors.serializeHash(sourceAggregationSet.selector { upscale_source: 'yes' }),
            }
          else
            expr,
      }],
}
