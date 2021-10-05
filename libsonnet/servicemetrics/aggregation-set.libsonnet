local durationParser = import 'utils/duration-parser.libsonnet';
local validator = import 'utils/validator.libsonnet';

local definitionDefaults = {
  aggregationFilter: null,

  // By default we generate SLO Analysis dashboards when
  // the aggregation set is not an intermediate source
  generateSLODashboards: !self.intermediateSource,
};

local arrayOfStringsValidator = validator.validator(
  function(v)
    std.isArray(v) && std.foldl(function(memo, e) memo && std.isString(e), v, true),
  'not an array of strings'
);

local buildValidator(definition) =
  local required = {
    selector: validator.object,
    labels: arrayOfStringsValidator,
  };
  local optionalBurnRates =
    if std.objectHas(definition, 'burnRates') then
      {
        burnRates: validator.object,
      } else {};
  local optionalGeneratedBurnRates =
    if std.objectHas(definition, 'metricFormats') ||
       std.objectHas(definition, 'supportedBurnRates') then
      {
        metricFormats: validator.object,
        supportedBurnRates: arrayOfStringsValidator,
      } else {};
  validator.new(required + optionalBurnRates + optionalGeneratedBurnRates);
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
    local unvalidatedDefinition = definitionDefaults + definition;
    local definitionWithDefaults = buildValidator(unvalidatedDefinition).assertValid(unvalidatedDefinition);

    local generateMetricNamesForBurnRate(burnRate) =
      if std.objectHas(definitionWithDefaults, 'metricFormats') &&
         std.objectHas(definitionWithDefaults, 'supportedBurnRates') &&
         std.member(definitionWithDefaults.supportedBurnRates, burnRate) then
        std.foldl(
          function(memo, metricKey)
            memo { [metricKey]: definitionWithDefaults.metricFormats[metricKey] % [burnRate] },
          std.objectFields(definitionWithDefaults.metricFormats),
          {}
        ) else {};

    local getBurnRateMetrics(burnRate) =
      if std.objectHas(definitionWithDefaults, 'burnRates') &&
         std.objectHas(definitionWithDefaults.burnRates, burnRate) then
        definitionWithDefaults.burnRates[burnRate]
      else
        generateMetricNamesForBurnRate(burnRate);

    local getMetricNameForBurnRate(burnRate, metricName, required) =
      local nullOrFail() =
        if required then
          std.assertEqual('', { __assert__: "'%s' metric for '%s' burn rate required, but not configured in aggregation set '%s'." % [metricName, burnRate, definitionWithDefaults.name] })
        else
          null;

      local burnRateMetrics = getBurnRateMetrics(burnRate);
      if std.objectHas(burnRateMetrics, metricName) then
        burnRateMetrics[metricName]
      else
        nullOrFail();

    definitionWithDefaults {
      // Returns the apdexSuccessRate metric name, null if not required, or fails if missing and required
      getApdexSuccessRateMetricForBurnRate(burnRate, required=false)::
        getMetricNameForBurnRate(burnRate, 'apdexSuccessRate', required),

      // Returns the apdexRatio metric name, null if not required, or fails if missing and required
      getApdexRatioMetricForBurnRate(burnRate, required=false)::
        getMetricNameForBurnRate(burnRate, 'apdexRatio', required),

      // Returns the apdexWeight metric name, null if not required, or fails if missing and required
      getApdexWeightMetricForBurnRate(burnRate, required=false)::
        getMetricNameForBurnRate(burnRate, 'apdexWeight', required),

      // Returns the opsRate metric name, null if not required, or fails if missing and required
      getOpsRateMetricForBurnRate(burnRate, required=false)::
        getMetricNameForBurnRate(burnRate, 'opsRate', required),

      // Returns the errorRate metric name, null if not required, or fails if missing and required
      getErrorRateMetricForBurnRate(burnRate, required=false)::
        getMetricNameForBurnRate(burnRate, 'errorRate', required),

      // Returns the errorRatio metric name, null if not required, or fails if missing and required
      getErrorRatioMetricForBurnRate(burnRate, required=false)::
        getMetricNameForBurnRate(burnRate, 'errorRatio', required),

      // Returns a set of burn rates for the aggregation set,
      // ordered by duration ascending
      getBurnRates()::
        local supportedBurnRates = if std.objectHas(self, 'supportedBurnRates') then self.supportedBurnRates else [];
        local definedBurnRates = if std.objectHas(self, 'burnRates') then
          std.objectFields(definitionWithDefaults.burnRates)
        else [];
        std.set(definedBurnRates + supportedBurnRates, durationParser.toSeconds),
    },
}
