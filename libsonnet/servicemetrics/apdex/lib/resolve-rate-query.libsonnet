local optionalOffset = import '../../lib/optional-offset.libsonnet';
local recordingRuleRegistry = import '../../recording-rule-registry.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

{
  resolveRateQuery(metricName, selector, rangeInterval, useRecordingRuleRegistry, offset, aggregationFunction=null, aggregationLabels=[])::
    local recordedRate = recordingRuleRegistry.resolveRecordingRuleFor(
      aggregationFunction=aggregationFunction,
      aggregationLabels=aggregationLabels,
      rangeVectorFunction='rate',
      metricName=metricName,
      rangeInterval=rangeInterval,
      selector=selector,
      offset=offset
    );
    if useRecordingRuleRegistry && recordedRate != null then
      recordedRate
    else
      local query = 'rate(%(metric)s{%(selector)s}[%(rangeInterval)s]%(optionalOffset)s)' % {
        metric: metricName,
        selector: selectors.serializeHash(selector),
        rangeInterval: rangeInterval,
        optionalOffset: optionalOffset(offset),
      };

      if aggregationFunction == null then
        query
      else
        aggregations.aggregateOverQuery(aggregationFunction, aggregationLabels, query),
}
