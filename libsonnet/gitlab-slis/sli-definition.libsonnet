local validator = import 'utils/validator.libsonnet';
local rateMetric = (import 'servicemetrics/rate.libsonnet').rateMetric;
local rateApdex = (import 'servicemetrics/rate_apdex.libsonnet').rateApdex;
local recordingRuleRegistry = import 'servicemetrics/recording-rule-registry.libsonnet';
local serviceLevelIndicatorDefinition = import 'servicemetrics/service_level_indicator_definition.libsonnet';
local misc = import 'utils/misc.libsonnet';

// We might add `success` and `error` in the future
// When adding support for these, please update the metrics catalog to add
// recording names to the aggregation sets and recording rules
local apdexKind = 'apdex';

local sliValidator = validator.new({
  name: validator.string,
  significantLabels: validator.array,
  description: validator.string,
  kind: validator.validator(function(value) value == apdexKind, 'only %s is supported' % apdexKind),
});

local operationRate(definition, selector) =
  rateMetric(definition.totalCounterName);
local successRate(definition, selector) =
  rateMetric(definition.successCounterName);

local validateAndApplyDefaults(definition) =
  local sli = sliValidator.assertValid(definition) {
    totalCounterName: 'gitlab_sli:%s:total' % [definition.name],
    successCounterName: 'gitlab_sli:%s:success_total' % [definition.name],
  };

  sli {
    aggregatedOperationRateQuery(selector={}, aggregationLabels=[], rangeInterval)::
      local labels = std.set(aggregationLabels + self.significantLabels);
      operationRate(self, selector).aggregatedRateQuery(labels, selector, rangeInterval),
    aggregatedSuccessRateQuery(selector={}, aggregationLabels=[], rangeInterval)::
      local labels = std.set(aggregationLabels + self.significantLabels);
      successRate(self, selector).aggregatedRateQuery(labels, selector, rangeInterval),
    recordingRuleMetrics: [sli.totalCounterName, sli.successCounterName],

    inRecordingRuleRegistry: misc.all(
      function(metricName)
        recordingRuleRegistry.resolveRecordingRuleFor(metricName=metricName) != null,
      self.recordingRuleMetrics,
    ),

    generateServiceLevelIndicator(extraSelector):: {
      userImpacting: true,
      featureCategory: if std.objectHas(sli, 'featureCategory') && sli.featureCategory != serviceLevelIndicatorDefinition.featureCategoryNotOwned then
        sli.featureCategory
      else if std.setMember('feature_category', sli.significantLabels) then
        serviceLevelIndicatorDefinition.featureCategoryFromSourceMetrics
      else
        serviceLevelIndicatorDefinition.featureCategoryNotOwned,

      description: sli.description,

      requestRate: operationRate(sli, extraSelector),
      significantLabels: sli.significantLabels,

      apdex: if sli.kind == apdexKind then
        rateApdex(sli.successCounterName, sli.totalCounterName, extraSelector)
      else
        null,
    },
  };

{
  apdexKind: apdexKind,

  new(definition):: validateAndApplyDefaults(definition),
}
