// Get the set of static labels for an aggregation
// The feature category will be included if the aggregation needs it and the SLI has
// a feature category
local staticLabelsForAggregation(serviceDefinition, sliDefinition, aggregationLabels) =
  local baseLabels = {
    tier: serviceDefinition.tier,
    type: serviceDefinition.type,
    component: sliDefinition.name,
  };
  if sliDefinition.hasStaticFeatureCategory() && std.member(aggregationLabels, 'feature_category')
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

// Generates the recording rules given a component definition
local generateRecordingRulesForComponent(burnRate, aggregationSet, serviceDefinition, sliDefinition, extraSourceSelector, config) =
  local recordingRuleStaticLabels = staticLabelsForAggregation(serviceDefinition, sliDefinition, aggregationSet.labels);

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
        // TODO: upscale longer burn rates from what is already recorded in the
        // aggregation set.
        // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2898
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
