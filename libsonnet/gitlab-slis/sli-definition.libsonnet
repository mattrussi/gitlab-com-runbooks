local validator = import 'utils/validator.libsonnet';
local rateMetric = (import 'servicemetrics/rate.libsonnet').rateMetric;

// We might add `success` and `error` in the future
// When adding support for these, please update the metrics catalog to add
// recording names to the aggregation sets and recording rules
local apdexKind = 'apdex';

local sliValidator = validator.new({
  name: validator.string,
  significantLabels: validator.array,
  kind: validator.validator(function(value) value == apdexKind, 'only %s is supported' % apdexKind),
});

local operationRate(definition, selector) =
  rateMetric(definition.totalCounterName);
local successRate(definition, selector) =
  rateMetric(definition.successCounterName);

local validateAndApplyDefaults(definition) =
  sliValidator.assertValid(definition) {
    totalCounterName: 'gitlab_sli:%s:total' % [definition.name],
    successCounterName: 'gitlab_sli:%s:success_total' % [definition.name],

    operationRate(selector={}):: operationRate(self, selector),
    successRate(selector={}):: successRate(self, selector),

    aggregatedOperationRateQuery(selector={}, aggregationLabels=[], rangeInterval)::
      local labels = std.set(aggregationLabels + self.significantLabels);
      self.operationRate().aggregatedRateQuery(labels, selector, rangeInterval),
    aggregatedSuccessRateQuery(selector={}, aggregationLabels=[], rangeInterval)::
      local labels = std.set(aggregationLabels + self.significantLabels);
      self.successRate().aggregatedRateQuery(labels, selector, rangeInterval),
  };

{
  apdexKind: apdexKind,

  new(definition):: validateAndApplyDefaults(definition),
}
