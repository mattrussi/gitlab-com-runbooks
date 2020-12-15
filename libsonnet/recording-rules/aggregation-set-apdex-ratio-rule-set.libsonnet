local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

{
  // Aggregates apdex scores from one aggregation set to another. Intended to be used
  // for aggregating Prometheus metrics into Thanos global view
  aggregationSetApdexRatioRuleSet(sourceAggregationSet, targetAggregationSet, burnRate)::
    local targetApdexRatioMetric = targetAggregationSet.getApdexRatioMetricForBurnRate(burnRate);
    local targetApdexWeightMetric = targetAggregationSet.getApdexWeightMetricForBurnRate(burnRate);
    local sourceApdexRatioMetric = sourceAggregationSet.getApdexRatioMetricForBurnRate(burnRate);
    local sourceApdexWeightMetric = sourceAggregationSet.getApdexWeightMetricForBurnRate(burnRate);

    local targetAggregationLabels = aggregations.serialize(targetAggregationSet.labels);


    local formatConfig = {
      targetApdexRatioMetric: targetApdexRatioMetric,
      targetApdexWeightMetric: targetApdexWeightMetric,
      sourceApdexRatioMetric: sourceApdexRatioMetric,
      sourceApdexWeightMetric: sourceApdexWeightMetric,
      targetAggregationLabels: targetAggregationLabels,
      sourceSelector: selectors.serializeHash(sourceAggregationSet.selector),
    };

    (
      if targetApdexWeightMetric == null then
        []
      else
        if sourceApdexWeightMetric == null then
          std.assertEqual(sourceApdexWeightMetric, { __assert__: 'Source aggregation set requires an apdex weight metric recording rule in order to be used in a downstream aggregation. Please add an apdexWeightMetric to the source' })
        else
          [{
            record: targetApdexWeightMetric,
            expr: |||
              sum by (%(targetAggregationLabels)s) (
                (%(sourceApdexWeightMetric)s{%(sourceSelector)s} >= 0)
              )
            ||| % formatConfig,
          }]
    )
    +
    (
      if targetApdexRatioMetric == null || sourceApdexRatioMetric == null then
        []
      else
        if sourceApdexWeightMetric == null then
          std.assertEqual(sourceApdexWeightMetric, { __assert__: 'Source aggregation set requires an apdex weight metric recording rule in order to be used in a downstream aggregation. Please add an apdexWeightMetric to the source' })
        else
          [{
            /** FYI: It may be possible to switch the denominator to the weight score above */
            record: targetApdexRatioMetric,
            expr: |||
              sum by (%(targetAggregationLabels)s) (
                (
                  (%(sourceApdexRatioMetric)s{%(sourceSelector)s} >= 0)
                  *
                  (%(sourceApdexWeightMetric)s{%(sourceSelector)s} >= 0)
                )
              )
              /
              sum by (%(targetAggregationLabels)s) (
                (%(sourceApdexWeightMetric)s{%(sourceSelector)s} >= 0)
              )
            ||| % formatConfig,
          }]
    ),


}
