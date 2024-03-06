local aggregationSetErrorRatioReflectedRuleSet = (import 'recording-rules/aggregation-set-reflected-ratio-rule-set.libsonnet').aggregationSetErrorRatioReflectedRuleSet;
local aggregationSetApdexRatioReflectedRuleSet = (import 'recording-rules/aggregation-set-reflected-ratio-rule-set.libsonnet').aggregationSetApdexRatioReflectedRuleSet;
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local filterLabelsFromLabelsHash = (import 'promql/labels.libsonnet').filterLabelsFromLabelsHash;
local optionalOffset = import 'recording-rules/lib/optional-offset.libsonnet';

// Get the set of static labels for an aggregation
// The feature category will be included if the aggregation needs it and the SLI has
// a feature category
local staticLabelsForAggregation(serviceDefinition, sliDefinition, aggregationSet) =
  local baseLabels = {
    tier: serviceDefinition.tier,
    type: serviceDefinition.type,
    component: sliDefinition.name,
  } + aggregationSet.recordingRuleStaticLabels;
  if sliDefinition.hasStaticFeatureCategory() && std.member(aggregationSet.labels, 'feature_category')
  then baseLabels + sliDefinition.staticFeatureCategoryLabels()
  else baseLabels;

// Generates apdex weight recording rules for a component definition
local generateApdexRules(burnRate, aggregationSet, sliDefinition, recordingRuleStaticLabels, extraSourceSelector, config) =
  local apdexSuccessRateRecordingRuleName = aggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate);
  local apdexWeightRecordingRuleName = aggregationSet.getApdexWeightMetricForBurnRate(burnRate);

  if apdexSuccessRateRecordingRuleName != null || apdexWeightRecordingRuleName != null then
    sliDefinition.generateApdexRecordingRules(
      burnRate=burnRate,
      aggregationSet=aggregationSet,
      recordingRuleStaticLabels=recordingRuleStaticLabels,
      selector=extraSourceSelector,
      config=config,
    )
  else
    [];

local generateRequestRateRules(burnRate, aggregationSet, sliDefinition, recordingRuleStaticLabels, extraSourceSelector, config) =
  local requestRateRecordingRuleName = aggregationSet.getOpsRateMetricForBurnRate(burnRate);
  if requestRateRecordingRuleName != null then
    sliDefinition.generateRequestRateRecordingRules(
      burnRate=burnRate,
      aggregationSet=aggregationSet,
      recordingRuleStaticLabels=recordingRuleStaticLabels,
      selector=extraSourceSelector,
      config=config,
    )
  else
    [];

local generateErrorRateRules(burnRate, aggregationSet, sliDefinition, recordingRuleStaticLabels, extraSourceSelector, config) =
  local errorRateRecordingRuleName = aggregationSet.getErrorRateMetricForBurnRate(burnRate);
  if errorRateRecordingRuleName != null then
    sliDefinition.generateErrorRateRecordingRules(
      burnRate=burnRate,
      aggregationSet=aggregationSet,
      recordingRuleStaticLabels=recordingRuleStaticLabels,
      selector=extraSourceSelector,
      config=config,
    )
  else
    [];

local generateErrorRatioRules(burnRate, aggregationSet, sliDefinition, recordingRuleStaticLabels, extraSourceSelector, config) =
  aggregationSetErrorRatioReflectedRuleSet(aggregationSet, burnRate, extraSourceSelector, recordingRuleStaticLabels);

local generateApdexRatioRules(burnRate, aggregationSet, sliDefinition, recordingRuleStaticLabels, extraSourceSelector, config) =
  aggregationSetApdexRatioReflectedRuleSet(aggregationSet, burnRate, extraSourceSelector, recordingRuleStaticLabels);

// Generates the recording rules given a component definition
local generateRecordingRulesForComponent(burnRate, aggregationSet, serviceDefinition, sliDefinition, extraSourceSelector, config) =
  local recordingRuleStaticLabels = staticLabelsForAggregation(serviceDefinition, sliDefinition, aggregationSet);

  std.flatMap(
    function(generator) generator(
      burnRate=burnRate,
      aggregationSet=aggregationSet,
      sliDefinition=sliDefinition,
      recordingRuleStaticLabels=recordingRuleStaticLabels,
      extraSourceSelector=extraSourceSelector,
      config=config,
    ),
    [
      generateApdexRules,
      generateRequestRateRules,
      generateErrorRateRules,  // Error rates should always go after request rates as we have a fallback clause which relies on request rate existing
      generateErrorRatioRules,
      generateApdexRatioRules,
    ]
  );

local upscaledRateExpression = |||
  sum by (%(aggregationLabels)s) (
    avg_over_time(%(metricName)s{%(sourceSelectorWithExtras)s}[%(burnRate)s]%(optionalOffset)s)
  )
|||;

local generateApdexRulesUpscaled(burnRate, aggregationSet, sliDefinition, recordingRuleStaticLabels, extraSourceSelector, config) =
  local apdexSuccessRateRuleName = aggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate, required=false);
  local apdexWeightRuleName = aggregationSet.getApdexWeightMetricForBurnRate(burnRate, required=false);
  local allStaticLabels = recordingRuleStaticLabels + sliDefinition.staticLabels;

  local apdexSuccessRateRule = if apdexSuccessRateRuleName != null then
    [{
      record: apdexSuccessRateRuleName,
      labels: allStaticLabels,
      expr: upscaledRateExpression % {
        aggregationLabels: aggregations.serialize(filterLabelsFromLabelsHash(aggregationSet.labels, allStaticLabels)),
        metricName: aggregationSet.getApdexSuccessRateMetricForBurnRate('1h', required=true),
        sourceSelectorWithExtras: selectors.serializeHash(
          selectors.merge(recordingRuleStaticLabels, extraSourceSelector),
        ),
        burnRate: burnRate,
        optionalOffset: optionalOffset(aggregationSet.offset),
      },
    }]
  else [];

  local apdexWeightRateRule = if apdexWeightRuleName != null then
    [{
      record: apdexWeightRuleName,
      labels: allStaticLabels,
      expr: upscaledRateExpression % {
        aggregationLabels: aggregations.serialize(filterLabelsFromLabelsHash(aggregationSet.labels, allStaticLabels)),
        metricName: aggregationSet.getApdexWeightMetricForBurnRate('1h', required=true),
        sourceSelectorWithExtras: selectors.serializeHash(
          selectors.merge(recordingRuleStaticLabels, extraSourceSelector),
        ),
        burnRate: burnRate,
        optionalOffset: optionalOffset(aggregationSet.offset),
      },
    }]
  else [];

  apdexSuccessRateRule + apdexWeightRateRule;

local generateRequestRateRulesUpscaled(burnRate, aggregationSet, sliDefinition, recordingRuleStaticLabels, extraSourceSelector, config) =
  local recordingRuleName = aggregationSet.getOpsRateMetricForBurnRate(burnRate, required=false);
  local allStaticLabels = recordingRuleStaticLabels + sliDefinition.staticLabels;

  if recordingRuleName != null then
    [{
      record: recordingRuleName,
      labels: allStaticLabels,
      expr: upscaledRateExpression % {
        aggregationLabels: aggregations.serialize(filterLabelsFromLabelsHash(aggregationSet.labels, allStaticLabels)),
        metricName: aggregationSet.getOpsRateMetricForBurnRate('1h', required=true),
        sourceSelectorWithExtras: selectors.serializeHash(
          selectors.merge(recordingRuleStaticLabels, extraSourceSelector),
        ),
        burnRate: burnRate,
        optionalOffset: optionalOffset(aggregationSet.offset),
      },
    }]
  else
    [];

local generateErrorRateRulesUpscaled(burnRate, aggregationSet, sliDefinition, recordingRuleStaticLabels, extraSourceSelector, config) =
  local recordingRuleName = aggregationSet.getErrorRateMetricForBurnRate(burnRate, required=false);
  local allStaticLabels = recordingRuleStaticLabels + sliDefinition.staticLabels;

  if recordingRuleName != null then
    [{
      record: recordingRuleName,
      labels: allStaticLabels,
      expr: upscaledRateExpression % {
        aggregationLabels: aggregations.serialize(filterLabelsFromLabelsHash(aggregationSet.labels, allStaticLabels)),
        metricName: aggregationSet.getErrorRateMetricForBurnRate('1h', required=true),
        sourceSelectorWithExtras: selectors.serializeHash(
          selectors.merge(recordingRuleStaticLabels, extraSourceSelector),
        ),
        burnRate: burnRate,
        optionalOffset: optionalOffset(aggregationSet.offset),
      },
    }]
  else
    [];


local generateUpscaledRecordingRulesForComponent(burnRate, aggregationSet, serviceDefinition, sliDefinition, extraSourceSelector, config) =
  local recordingRuleStaticLabels = staticLabelsForAggregation(serviceDefinition, sliDefinition, aggregationSet);

  std.flatMap(
    function(generator) generator(
      burnRate=burnRate,
      aggregationSet=aggregationSet,
      sliDefinition=sliDefinition,
      recordingRuleStaticLabels=recordingRuleStaticLabels,
      extraSourceSelector=extraSourceSelector,
      config=config,
    ),
    [
      generateApdexRulesUpscaled,
      generateRequestRateRulesUpscaled,
      generateErrorRateRulesUpscaled,
      generateErrorRatioRules,
      generateApdexRatioRules,
    ]
  );

{
  // This component metrics ruleset applies the key metrics recording rules for
  // each component in the metrics catalog
  componentMetricsRuleSetGenerator(
    burnRate,
    aggregationSet,
    extraSourceSelector={},
    config={},
  )::
    {
      config: config,
      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition, serviceLevelIndicators=serviceDefinition.listServiceLevelIndicators())::

        if aggregationSet.upscaleBurnRate(burnRate) then
          std.flatMap(
            function(sliDefinition) generateUpscaledRecordingRulesForComponent(
              burnRate=burnRate,
              aggregationSet=aggregationSet,
              serviceDefinition=serviceDefinition,
              sliDefinition=sliDefinition,
              extraSourceSelector=extraSourceSelector,
              config=self.config,
            ),
            serviceLevelIndicators,
          ) else
          std.flatMap(
            function(sliDefinition) generateRecordingRulesForComponent(
              burnRate=burnRate,
              aggregationSet=aggregationSet,
              serviceDefinition=serviceDefinition,
              sliDefinition=sliDefinition,
              extraSourceSelector=extraSourceSelector,
              config=self.config,
            ),
            serviceLevelIndicators,
          ),
    },

}
