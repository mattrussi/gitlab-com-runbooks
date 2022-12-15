local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local misc = import 'utils/misc.libsonnet';

{
  new(keyServices, aggregationSet):: {
    local burnRate = '1h',  // use the one hour burn rate as the largest non-upscaled one

    local serviceSelector = selectors.serializeHash({ type: { oneOf: keyServices } }),

    local formatConfig = {
      aggregationLabels: aggregations.serialize(aggregationSet.labels),
      selector: serviceSelector,
      apdexSuccessRate: aggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate, required=true),
      errorRate: aggregationSet.getErrorRateMetricForBurnRate(burnRate, required=true),
      apdexWeight: aggregationSet.getApdexWeightMetricForBurnRate(burnRate, required=true),
      opsRate: aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=true),
    },

    local successRate = |||
      (
        sum by(%(aggregationLabels)s) (
          %(apdexSuccessRate)s{%(selector)s}
        )
        +
        sum by (%(aggregationLabels)s)(
          %(opsRate)s{%(selector)s} - %(errorRate)s{%(selector)s}
        )
      )
    ||| % formatConfig,

    local opsRate = |||
      (
        sum by(%(aggregationLabels)s) (
          %(opsRate)s{%(selector)s}
        )
        +
        sum by (%(aggregationLabels)s) (
          %(apdexWeight)s{%(selector)s}
        )
      )
    ||| % formatConfig,

    successRate: successRate,
    opsRate: opsRate,

    local availabilityOpsRate = 'gitlab:availability:ops:rate_%s' % [burnRate],
    local availabilitySuccessRate = 'gitlab:availability:success:rate_%s' % [burnRate],
    availabilityRatio(aggregationLabels, selector, range, services):
      local selectorIncludingServices = selector { type: { oneOf: services } };
      |||
        sum by (%(aggregationLabels)s) (
          sum_over_time(%(availabilitySuccessRate)s{%(selector)s}[%(range)s])
        )
        /
        sum by (%(aggregationLabels)s) (
          sum_over_time(%(availabilityOpsRate)s{%(selector)s}[%(range)s])
        )
      ||| % {
        aggregationLabels: aggregations.join(aggregationLabels),
        selector: selectors.serializeHash(selectorIncludingServices),
        range: range,
        availabilitySuccessRate: availabilitySuccessRate,
        availabilityOpsRate: availabilityOpsRate,
      },

    rateRules: [
      {
        record: availabilityOpsRate,
        expr: aggregations.aggregateOverQuery('sum', formatConfig.aggregationLabels, opsRate),
      },
      {
        record: availabilitySuccessRate,
        expr: aggregations.aggregateOverQuery('sum', formatConfig.aggregationLabels, successRate),
      },
    ],
  },
}
