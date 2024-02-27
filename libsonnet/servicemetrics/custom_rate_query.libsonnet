local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local metricLabelsSelectorsMixin = (import './metrics-mixin.libsonnet').metricLabelsSelectorsMixin;
local validateMetric = (import './validation.libsonnet').validateMetric;

{
  // A custom rate query allows arbitrary PromQL to be used as a rate query
  // This can be helpful if the metric is exposed as a gauge or in another manner
  customRateQuery(
    query,
    metric,
    selector
  ):: validateMetric({
    query: query,
    metric: metric,
    selector: selector,
    useRecordingRuleRegistry:: false,
    aggregatedRateQuery(aggregationLabels, selector, rangeInterval, withoutLabels=[], offset=null)::
      local combinedSelector = selectors.without(selectors.merge(self.selector, selector), withoutLabels);
      // Note that we ignore the rangeInterval, selectors, offset, and withoutLabels for now
      // TODO: handle those better, if we can
      local queryText = query % {
        burnRate: rangeInterval,
        aggregationLabels: aggregations.serialize(aggregationLabels),
        metric: metric,
        selector: selectors.serializeHash(combinedSelector),
      };
      aggregations.aggregateOverQuery('sum', aggregationLabels, queryText),
  } + metricLabelsSelectorsMixin(selector, [metric])),
}
