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
    local aggregationFilter = targetAggregationSet.aggregationFilter;
    local sourceSelector = selectors.serializeHash(sourceAggregationSet.selector);

    local formatConfig = {
      targetApdexRatioMetric: targetApdexRatioMetric,
      targetApdexWeightMetric: targetApdexWeightMetric,
      targetAggregationLabels: targetAggregationLabels,
      sourceSelector: sourceSelector,
      aggregationFilterExpr:
        // For service level aggregations, we need to filter out any SLIs which we don't want to include
        // in the service level aggregation.
        // These are defined in the SLI with `aggregateToService:false`
        if aggregationFilter != null then
          ' and on(component, type) (gitlab_component_service:mapping{monitor="global", %(aggregationFilter)s_aggregation="yes"})' % {
            sourceSelector: sourceSelector,
            aggregationFilter: aggregationFilter,
          }
        else
          '',
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
                  sum by (%(targetAggregationLabels)s) (
                    sum_over_time(%(apdexSuccessRateMetric1h)s{%(sourceSelectorWithUpscale)s}[6h])%(aggregationFilterExpr)s
                  )
                  /
                  sum by (%(targetAggregationLabels)s) (
                    sum_over_time(%(sourceApdexWeightMetric1h)s{%(sourceSelectorWithUpscale)s}[6h])%(aggregationFilterExpr)s
                  )
                )
              ||| % formatConfig {
                expr: expr,
                sourceApdexWeightMetric1h: sourceAggregationSet.getApdexWeightMetricForBurnRate('1h', required=true),
                apdexSuccessRateMetric1h: sourceAggregationSet.getApdexSuccessRateMetricForBurnRate('1h', required=true),
                sourceApdexSuccessRateMetric: sourceApdexSuccessRateMetric,
                sourceApdexWeightMetric: sourceApdexWeightMetric,
                sourceSelectorWithUpscale: selectors.serializeHash(sourceAggregationSet.selector { upscale_source: 'yes' }),
              }
            else
              expr,
        }]
    ),


}
