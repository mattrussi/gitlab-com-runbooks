local resolveRateQuery = (import './lib/resolve-rate-query.libsonnet').resolveRateQuery;
local aggregations = import 'promql/aggregations.libsonnet';
local generateApdexAttributionQuery = (import './lib/counter-apdex-attribution-query.libsonnet').attributionQuery;

local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

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
  successCounterApdex(successRateMetric, operationRateMetric, selector=''):: {
    successRateMetric: successRateMetric,
    operationRateMetric: operationRateMetric,
    selector: selector,

    apdexSuccessRateQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[])::
      resolveRateQuery(
        self.successRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        aggregationLabels=aggregationLabels,
        aggregationFunction='sum',
      ),
    apdexWeightQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[])::
      resolveRateQuery(
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
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
      ),

    apdexDenominator(selector, rangeInterval, withoutLabels=[])::
      resolveRateQuery(
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
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
