local resolveRateQuery = (import './lib/resolve-rate-query.libsonnet').resolveRateQuery;
local aggregations = import 'promql/aggregations.libsonnet';
local generateApdexAttributionQuery = (import './lib/counter-apdex-attribution-query.libsonnet').attributionQuery;

local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';
local validateSelector = (import '../validation.libsonnet').validateSelector;

local generateApdexRatio(successCounterApdex, aggregationLabels, additionalSelectors, rangeInterval, withoutLabels=[]) =
  |||
    %(successRateQuery)s
    /
    %(weightQuery)s
  ||| % {
    successRateQuery: successCounterApdex.successRateQuery(aggregationLabels, additionalSelectors, rangeInterval, withoutLabels=withoutLabels),
    weightQuery: successCounterApdex.apdexWeightQuery(aggregationLabels, additionalSelectors, rangeInterval, withoutLabels=withoutLabels),
  };

{
  successCounterApdex(successRateMetric, operationRateMetric, selector={}, useRecordingRuleRegistry=true):: {
    successRateMetric: successRateMetric,
    operationRateMetric: operationRateMetric,
    selector: validateSelector(selector),
    useRecordingRuleRegistry:: useRecordingRuleRegistry,

    apdexSuccessRateQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[], offset=null)::
      resolveRateQuery(
        self.successRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        useRecordingRuleRegistry,
        offset,
        aggregationLabels=aggregationLabels,
        aggregationFunction='sum',
      ),
    apdexWeightQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[], offset=null)::
      resolveRateQuery(
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        useRecordingRuleRegistry,
        offset,
        aggregationLabels=aggregationLabels,
        aggregationFunction='sum'
      ),
    apdexQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[])::
      generateApdexRatio(self, aggregationLabels, selector, rangeInterval, withoutLabels=withoutLabels),

    apdexNumerator(selector, rangeInterval, withoutLabels=[])::
      resolveRateQuery(
        self.successRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        useRecordingRuleRegistry,
      ),

    apdexDenominator(selector, rangeInterval, withoutLabels=[])::
      resolveRateQuery(
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        useRecordingRuleRegistry,
      ),

    apdexAttribution(aggregationLabel, selector, rangeInterval, withoutLabels=[])::
      generateApdexAttributionQuery(self, aggregationLabel, selector, rangeInterval, withoutLabels),

    // Only support reflection on hash selectors
    [if std.isObject(selector) then 'supportsReflection']():: {
      // Returns a list of metrics and the labels that they use
      getMetricNamesAndLabels()::
        {
          [successRateMetric]: std.set(std.objectFields(selector)),
          [operationRateMetric]: std.set(std.objectFields(selector)),
        },
    },
  },
}
