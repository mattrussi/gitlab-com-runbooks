local resolveRateQuery = (import './lib/resolve-rate-query.libsonnet').resolveRateQuery;
local generateApdexAttributionQuery = (import './lib/counter-apdex-attribution-query.libsonnet').attributionQuery;
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local transformErrorRateToSuccessRate(errorRateMetric, operationRateMetric, selector, rangeInterval, aggregationLabels, useRecordingRuleRegistry=true) =
  |||
    %(operationRate)s - (
      %(errorRate)s or
      0 * %(indentedOperationRate)s
    )
  ||| % {
    operationRate: strings.chomp(resolveRateQuery(
      operationRateMetric, selector, rangeInterval, aggregationFunction='sum', aggregationLabels=aggregationLabels, useRecordingRuleRegistry=useRecordingRuleRegistry
    )),
    indentedOperationRate: strings.indent(strings.chomp(resolveRateQuery(
      operationRateMetric, selector, rangeInterval, aggregationFunction='sum', aggregationLabels=aggregationLabels, useRecordingRuleRegistry=useRecordingRuleRegistry
    )), 2),
    errorRate: strings.indent(strings.chomp(resolveRateQuery(
      errorRateMetric, selector, rangeInterval, aggregationFunction='sum', aggregationLabels=aggregationLabels, useRecordingRuleRegistry=useRecordingRuleRegistry
    )), 2),
  };


{
  // errorCounterApdex constructs an apdex score (ie, successes/total) from an error score (ie, errors/total).
  // This can be useful for latency metrics that count latencies that exceed threshold, instead of the more
  // common form of latencies that are within threshold.
  errorCounterApdex(errorRateMetric, operationRateMetric, selector):: {
    errorRateMetric: errorRateMetric,
    operationRateMetric: operationRateMetric,
    selector: selector,

    apdexSuccessRateQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[], useRecordingRuleRegistry=true)::
      transformErrorRateToSuccessRate(
        self.errorRateMetric,
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        aggregationLabels,
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
    apdexNumerator(selector, rangeInterval, withoutLabels=[], useRecordingRuleRegistry=true)::
      transformErrorRateToSuccessRate(
        self.errorRateMetric,
        self.operationRateMetric,
        selectors.without(selectors.merge(self.selector, selector), withoutLabels),
        rangeInterval,
        [],
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
      generateApdexAttributionQuery(self, aggregationLabel, selector, rangeInterval, withoutLabels, useRecordingRuleRegistry=useRecordingRuleRegistry),

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
