local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local recordingRuleRegistry = import 'recording-rule-registry.libsonnet';
local strings = import 'utils/strings.libsonnet';

local resolveRateQuery(metricName, selector, rangeInterval, aggregationFunction=null, aggregationLabels=[]) =
  local recordedRate = recordingRuleRegistry.resolveRecordingRuleFor(
    aggregationFunction=aggregationFunction,
    aggregationLabels=aggregationLabels,
    rangeVectorFunction='rate',
    metricName=metricName,
    rangeInterval=rangeInterval,
    selector=selector,
  );
  if recordedRate != null then
    recordedRate
  else
    local query = 'rate(%(metric)s{%(selector)s}[%(rangeInterval)s])' % {
      metric: metricName,
      selector: selectors.serializeHash(selector),
      rangeInterval: rangeInterval,
    };

    if aggregationFunction == null then
      query
    else
      aggregations.aggregateOverQuery(aggregationFunction, aggregationLabels, query);

local generateApdexRatio(rateApdex, aggregationLabels, additionalSelectors, rangeInterval) =
  |||
    %(successRateQuery)s
    /
    %(weightQuery)s
  ||| % {
    successRateQuery: rateApdex.successRateQuery(aggregationLabels, additionalSelectors, rangeInterval),
    weightQuery: rateApdex.apdexWeightQuery(aggregationLabels, additionalSelectors, rangeInterval),
  };

local generateApdexAttributionQuery(rateApdex, aggregationLabel, selector, rangeInterval) =
  |||
    (
      (
        %(splitTotalQuery)s
        -
        %(splitSuccessRateQuery)s
      )
      / ignoring (%(aggregationLabel)s) group_left()
      (
        %(aggregatedTotalQuery)s
      )
    )
  ||| % {
    splitTotalQuery: strings.indent(rateApdex.apdexWeightQuery([aggregationLabel], selector, rangeInterval), 4),
    splitSuccessRateQuery: strings.indent(rateApdex.apdexSuccessRateQuery([aggregationLabel], selector, rangeInterval), 4),
    aggregationLabel: aggregationLabel,
    aggregatedTotalQuery: strings.indent(rateApdex.apdexWeightQuery([], selector, rangeInterval), 4),
  };
{
  rateApdex(successRateMetric, operationRateMetric, selector=''):: {
    successRateMetric: successRateMetric,
    operationRateMetric: operationRateMetric,
    selector: selector,

    apdexSuccessRateQuery(aggregationLabels, selector, rangeInterval)::
      resolveRateQuery(
        self.successRateMetric,
        selectors.merge(self.selector, selector),
        rangeInterval,
        aggregationLabels=aggregationLabels,
        aggregationFunction='sum',
      ),
    apdexWeightQuery(aggregationLabels, selector, rangeInterval)::
      resolveRateQuery(
        self.operationRateMetric,
        selectors.merge(self.selector, selector),
        rangeInterval,
        aggregationLabels=aggregationLabels,
        aggregationFunction='sum'
      ),
    apdexQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexRatio(self, aggregationLabels, selector, rangeInterval),

    apdexNumerator(selector, rangeInterval)::
      resolveRateQuery(
        self.successRateMetric,
        selectors.merge(self.selector, selector),
        rangeInterval,
      ),

    apdexDenominator(selector, rangeInterval)::
      resolveRateQuery(
        self.operationRateMetric,
        selectors.merge(self.selector, selector),
        rangeInterval,
      ),

    apdexAttribution(aggregationLabel, selector, rangeInterval)::
      generateApdexAttributionQuery(self, aggregationLabel, selector, rangeInterval),

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
