local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local optionalOffset = import 'recording-rules/lib/optional-offset.libsonnet';

{
  // A rate that is precalcuated, not stored as a counter
  // Some metrics from stackdriver are presented in this form
  gaugeMetric(
    gauge,
    selector=null
  ):: {
    useRecordingRuleRegistry:: false,

    local baseSelector = selector,  // alias
    aggregatedRateQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[], offset=null)::
      local mergedSelectors = selectors.without(selectors.merge(baseSelector, selector), withoutLabels);
      local query = 'avg_over_time(%(gauge)s{%(selectors)s}[%(rangeInterval)s]%(optionalOffset)s)' % {
        gauge: gauge,
        selectors: selectors.serializeHash(mergedSelectors),
        rangeInterval: rangeInterval,
        optionalOffset: optionalOffset(offset),
      };

      aggregations.aggregateOverQuery('sum', aggregationLabels, query),
  },
}
