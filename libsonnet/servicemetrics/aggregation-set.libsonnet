local durationParser = import 'utils/duration-parser.libsonnet';

local definitionDefaults = {
  serviceLevelAggregation: false,
};

/**
 * An AggregationSet defines a matrix of aggregations across a series of different burn rates,
 * with a common set of aggregation labels and selectors.
 *
 *  {
 *    // Selectors applied to the source recording rules
 *    selector: { monitor: { ne: 'global' } },  // Not Thanos Ruler
 *
 *    // The labels to aggregate over, common to all recording rules in
 *    labels: ['environment', 'tier', 'type', 'stage'],
 *
 *    // burnRates is a map of burnRates at which the recording rule will be evaluated
 *    burnRates: {
 *      // For each burn rate, we define the names of the target recording rules
 *      '1m': {
 *        apdexRatio: 'gitlab_component_apdex:ratio',
 *        apdexWeight: 'gitlab_component_apdex:weight:score',
 *        opsRate: 'gitlab_component_ops:rate',
 *        errorRate: 'gitlab_component_errors:rate',
 *        errorRatio: 'gitlab_component_errors:ratio',
 *      },
 *      // Next burn rate...
 *    },
 *  }
 */

{
  AggregationSet(definition)::
    local definitionWithDefaults = definitionDefaults + definition;

    local getMetricNameForBurnRate(burnRate, metricName) =
      if std.objectHas(definitionWithDefaults.burnRates, burnRate) then
        local burnDef = definitionWithDefaults.burnRates[burnRate];
        if std.objectHas(burnDef, metricName) then
          burnDef[metricName]
        else
          null
      else
        null;

    definitionWithDefaults {
      // Returns the apdexRatio metric name or null
      getApdexRatioMetricForBurnRate(burnRate)::
        getMetricNameForBurnRate(burnRate, 'apdexRatio'),

      // Returns the apdexRatio metric name or null
      getApdexWeightMetricForBurnRate(burnRate)::
        getMetricNameForBurnRate(burnRate, 'apdexWeight'),

      // Returns the opsRate metric name or null
      getOpsRateMetricForBurnRate(burnRate)::
        getMetricNameForBurnRate(burnRate, 'opsRate'),

      // Returns the errorRate metric name or null
      getErrorRateMetricForBurnRate(burnRate)::
        getMetricNameForBurnRate(burnRate, 'errorRate'),

      // Returns the errorRatio metric name or null
      getErrorRatioMetricForBurnRate(burnRate)::
        getMetricNameForBurnRate(burnRate, 'errorRatio'),

      // Returns a set of burn rates for the aggregation set,
      // ordered by duration ascending
      getBurnRates()::
        std.set(std.objectFields(definitionWithDefaults.burnRates), durationParser.toSeconds),

      // Given another aggregation set, returns the common set of burn rates
      getCommonBurnRates(aggregationSetB)::
        local burnRates = self.getBurnRates();
        local burnRatesB = aggregationSetB.getBurnRates();

        std.setInter(burnRates, burnRatesB, durationParser.toSeconds),
    },
}
