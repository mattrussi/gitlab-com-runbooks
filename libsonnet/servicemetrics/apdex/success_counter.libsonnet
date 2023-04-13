local resolveRateQuery = (import './lib/resolve-rate-query.libsonnet').resolveRateQuery;
local aggregations = import 'promql/aggregations.libsonnet';
local generateApdexAttributionQuery = (import './lib/counter-apdex-attribution-query.libsonnet').attributionQuery;

local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local generateApdexRatio(successCounterApdex, aggregationLabels, additionalSelectors, rangeInterval, withoutLabels=[], useRecordingRuleRegistry) =
  |||
    %(successRateQuery)s
    /
    %(weightQuery)s
  ||| % {
    successRateQuery: successCounterApdex.successRateQuery(aggregationLabels, additionalSelectors, rangeInterval, withoutLabels=withoutLabels, useRecordingRuleRegistry=useRecordingRuleRegistry),
    weightQuery: successCounterApdex.apdexWeightQuery(aggregationLabels, additionalSelectors, rangeInterval, withoutLabels=withoutLabels, useRecordingRuleRegistry=useRecordingRuleRegistry),
  };

{
  successCounterApdex(successRateMetric, operationRateMetric, selector=''):: {
    successRateMetric: successRateMetric,
    operationRateMetric: operationRateMetric,
    selector: selector,

    apdexSuccessRateQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[], useRecordingRuleRegistry=true)::
      resolveRateQuery(
        self.successRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        aggregationLabels=aggregationLabels,
        aggregationFunction='sum',
        useRecordingRuleRegistry=useRecordingRuleRegistry,
      ),
    apdexWeightQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[], useRecordingRuleRegistry=true)::
      resolveRateQuery(
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        aggregationLabels=aggregationLabels,
        aggregationFunction='sum',
        useRecordingRuleRegistry=useRecordingRuleRegistry,
      ),
    apdexQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[], useRecordingRuleRegistry=true)::
      generateApdexRatio(self, aggregationLabels, selector, rangeInterval, withoutLabels=withoutLabels, useRecordingRuleRegistry=true),

    apdexNumerator(selector, rangeInterval, withoutLabels=[], useRecordingRuleRegistry=true)::
      resolveRateQuery(
        self.successRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        useRecordingRuleRegistry=useRecordingRuleRegistry,
      ),

    apdexDenominator(selector, rangeInterval, withoutLabels=[], useRecordingRuleRegistry=true)::
      resolveRateQuery(
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        useRecordingRuleRegistry=useRecordingRuleRegistry,
      ),

    apdexAttribution(aggregationLabel, selector, rangeInterval, withoutLabels=[], useRecordingRuleRegistry=true)::
      generateApdexAttributionQuery(self, aggregationLabel, selector, rangeInterval, withoutLabels, useRecordingRuleRegistry=true),

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
