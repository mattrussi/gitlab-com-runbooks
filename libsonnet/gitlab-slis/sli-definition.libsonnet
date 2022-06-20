local validator = import 'utils/validator.libsonnet';
local rateMetric = (import 'servicemetrics/rate.libsonnet').rateMetric;
local rateApdex = (import 'servicemetrics/rate_apdex.libsonnet').rateApdex;
local recordingRuleRegistry = import 'servicemetrics/recording-rule-registry.libsonnet';
local serviceLevelIndicatorDefinition = import 'servicemetrics/service_level_indicator_definition.libsonnet';
local misc = import 'utils/misc.libsonnet';
local stages = import 'service-catalog/stages.libsonnet';
local combined = (import 'servicemetrics/combined.libsonnet').combined;

// When adding new kinds, please update the metrics catalog to add recording
// names to the aggregation sets and recording rules
local apdexKind = 'apdex';
local errorRateKind = 'error_rate';
local validKinds = [apdexKind, errorRateKind];

local validateFeatureCategory(value) =
  if value == serviceLevelIndicatorDefinition.featureCategoryFromSourceMetrics then
    true
  else if value != null then
    std.objectHas(stages.featureCategoryMap, value)
  else
    false;

local sliValidator = validator.new({
  name: validator.string,
  significantLabels: validator.array,
  description: validator.string,
  kinds: validator.and(
    validator.validator(function(values) std.isArray(values) && std.length(values) > 0, 'must be present'),
    validator.validator(function(values) misc.all(function(v) std.member(validKinds, v), values), 'only %s are supported' % [std.join(', ', validKinds)])
  ),
  metricNameSeparator: validator.and(
    validator.string,
    validator.validator(function(value) std.length(value) == 1, 'must be one char long')
  ),
  featureCategory: validator.validator(validateFeatureCategory, 'please specify a known feature category or include `feature_category` as a significant label'),
});

local rateQueryFunction(sli, counter) =
  function(selector={}, aggregationLabels=[], rangeInterval)
    local labels = std.set(aggregationLabels + sli.significantLabels);
    rateMetric(sli[counter], selector).aggregatedRateQuery(labels, selector, rangeInterval);

local applyDefaults(definition) = {
  featureCategory: if std.member(definition.significantLabels, 'feature_category') then
    serviceLevelIndicatorDefinition.featureCategoryFromSourceMetrics,
  metricNameSeparator: '_',
  hasApdex():: std.member(definition.kinds, apdexKind),
  hasErrorRate():: std.member(definition.kinds, errorRateKind),

  // Temporary default fallback while we work on
  // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1760
  fallback: definition { metricNameSeparator: ':', fallback: null },
} + definition;

local validateAndApplyDefaults(definition) =
  local definitionWithDefaults = applyDefaults(definition);
  local sli = sliValidator.assertValid(definitionWithDefaults);

  local fallback = if definitionWithDefaults.fallback != null then
    validateAndApplyDefaults(definitionWithDefaults.fallback)
  else
    null;

  sli {
    local templateVariables = { name: sli.name, separator: sli.metricNameSeparator },
    [if sli.hasApdex() then 'apdexTotalCounterName']: 'gitlab_sli%(separator)s%(name)s_apdex%(separator)stotal' % templateVariables,
    [if sli.hasApdex() then 'apdexSuccessCounterName']: 'gitlab_sli%(separator)s%(name)s_apdex%(separator)ssuccess_total' % templateVariables,
    [if sli.hasErrorRate() then 'errorTotalCounterName']: 'gitlab_sli%(separator)s%(name)s%(separator)stotal' % templateVariables,
    [if sli.hasErrorRate() then 'errorCounterName']: 'gitlab_sli%(separator)s%(name)s%(separator)serror_total' % templateVariables,
    totalCounterName: if sli.hasErrorRate() then self.errorTotalCounterName else self.apdexTotalCounterName,

    [if sli.hasApdex() then 'aggregatedApdexOperationRateQuery']:: rateQueryFunction(self, 'apdexTotalCounterName'),
    [if sli.hasApdex() then 'aggregatedApdexSuccessRateQuery']:: rateQueryFunction(self, 'apdexSuccessCounterName'),
    [if sli.hasErrorRate() then 'aggregatedOperationRateQuery']:: rateQueryFunction(self, 'errorTotalCounterName'),
    [if sli.hasErrorRate() then 'aggregatedErrorRateQuery']:: rateQueryFunction(self, 'errorCounterName'),

    recordingRuleMetrics: std.filter(misc.isPresent, [
      misc.dig(self, ['apdexTotalCounterName']),
      misc.dig(self, ['apdexSuccessCounterName']),
      misc.dig(self, ['errorTotalCounterName']),
      misc.dig(self, ['errorCounterName']),
    ]) + if fallback != null then fallback.recordingRuleMetrics else [],

    inRecordingRuleRegistry: misc.all(
      function(metricName)
        recordingRuleRegistry.resolveRecordingRuleFor(metricName=metricName) != null,
      self.recordingRuleMetrics,
    ),

    local parent = self,

    generateServiceLevelIndicator(extraSelector):: {
      userImpacting: true,
      featureCategory: sli.featureCategory,

      description: parent.description,

      local fallbackSLI = if fallback != null then fallback.generateServiceLevelIndicator(extraSelector) else null,

      local requestRate = rateMetric(parent.totalCounterName, extraSelector),
      requestRate: if fallbackSLI == null then
        requestRate
      else
        combined([
          requestRate,
          fallbackSLI.requestRate,
        ]),

      significantLabels: parent.significantLabels + if fallback != null then
        fallback.significantLabels
      else [],

      local apdex = rateApdex(parent.apdexSuccessCounterName, parent.apdexTotalCounterName, extraSelector),
      [if parent.hasApdex() then 'apdex']: if fallbackSLI == null then
        apdex
      else
        combined([apdex, fallbackSLI.apdex]),

      local errorRate = rateMetric(parent.errorCounterName, extraSelector),
      [if parent.hasErrorRate() then 'errorRate']: if fallback == null then
        errorRate
      else
        combined([errorRate, fallbackSLI.errorRate]),
    },
  };

{
  apdexKind: apdexKind,
  errorRateKind: errorRateKind,

  new(definition):: validateAndApplyDefaults(definition),

  // For testing only
  _sliValidator:: sliValidator,
  _applyDefaults:: applyDefaults,
}
