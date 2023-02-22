local resolveRateQuery = (import './lib/resolve-rate-query.libsonnet').resolveRateQuery;
local generateApdexAttributionQuery = (import './lib/success-rate-apdex-attribution-query.libsonnet').attributionQuery;
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local transformErrorRateToSuccessRate(errorRateMetric, operationRateMetric, selector, rangeInterval, aggregationLabels) =
  |||
    %(operationRate)s - (
      %(errorRate)s or
      0 * %(indentedOperationRate)s
    )
  ||| % {
    operationRate: strings.chomp(resolveRateQuery(
      operationRateMetric, selector, rangeInterval, aggregationFunction='sum', aggregationLabels=aggregationLabels
    )),
    indentedOperationRate: strings.indent(strings.chomp(resolveRateQuery(
      operationRateMetric, selector, rangeInterval, aggregationFunction='sum', aggregationLabels=aggregationLabels
    )), 2),
    errorRate: strings.indent(strings.chomp(resolveRateQuery(
      errorRateMetric, selector, rangeInterval, aggregationFunction='sum', aggregationLabels=aggregationLabels
    )), 2),
  };


{
  errorCounterApdex(errorRateMetric, operationRateMetric, selector):: {
    errorRateMetric: errorRateMetric,
    operationRateMetric: operationRateMetric,
    selector: selector,

    apdexSuccessRateQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[])::
      transformErrorRateToSuccessRate(
        self.errorRateMetric,
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        aggregationLabels,
      ),
    apdexWeightQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[])::
      resolveRateQuery(
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        aggregationLabels=aggregationLabels,
        aggregationFunction='sum'
      ),
    apdexNumerator(selector, rangeInterval, withoutLabels=[])::
      transformErrorRateToSuccessRate(
        self.errorRateMetric,
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        [],
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
          [errorRateMetric]: std.set(std.objectFields(selector)),
          [operationRateMetric]: std.set(std.objectFields(selector)),
        },
    },
  },
}
