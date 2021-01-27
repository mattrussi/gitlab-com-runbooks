local selectors = import 'promql/selectors.libsonnet';

{
  aggregationSetErrorRatioRuleSet(aggregationSet, burnRate)::
    local errorRatioMetric = aggregationSet.getErrorRatioMetricForBurnRate(burnRate);
    local opsRateMetric = aggregationSet.getOpsRateMetricForBurnRate(burnRate);
    local errorRateMetric = aggregationSet.getErrorRateMetricForBurnRate(burnRate);

    local formatConfig = {
      opsRateMetric: opsRateMetric,
      errorRateMetric: errorRateMetric,
      selector: selectors.serializeHash(aggregationSet.selector),
    };

    if errorRatioMetric == null || opsRateMetric == null || errorRateMetric == null then
      []
    else
      [{
        record: errorRatioMetric,
        expr: |||
          %(errorRateMetric)s{%(selector)s}
          /
          %(opsRateMetric)s{%(selector)s}
        ||| % formatConfig,
      }],
}
