// Generates apdex weight recording rules for a component definition

local generateApdexRules(burnRate, aggregationSet, aggregationLabels, sliDefinition, recordingRuleStaticLabels) =
  local apdexSuccessRateRecordingRuleName = aggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate);
  local apdexWeightRecordingRuleName = aggregationSet.getApdexWeightMetricForBurnRate(burnRate);

  if apdexSuccessRateRecordingRuleName != null || apdexWeightRecordingRuleName != null then
    sliDefinition.generateApdexRecordingRules(
      burnRate=burnRate,
      aggregationSet=aggregationSet,
      aggregationLabels=aggregationLabels,
      recordingRuleStaticLabels=recordingRuleStaticLabels
    )
  else
    [];

local generateRequestRateRules(burnRate, aggregationSet, aggregationLabels, sliDefinition, recordingRuleStaticLabels) =
  local requestRateRecordingRuleName = aggregationSet.getOpsRateMetricForBurnRate(burnRate);

  // All components have a requestRate metric
  if requestRateRecordingRuleName != null then
    sliDefinition.generateRequestRateRecordingRules(
      burnRate=burnRate,
      recordingRuleName=requestRateRecordingRuleName,
      aggregationLabels=aggregationLabels,
      recordingRuleStaticLabels=recordingRuleStaticLabels
    )
  else
    [];

local generateErrorRateRules(burnRate, aggregationSet, aggregationLabels, sliDefinition, recordingRuleStaticLabels) =
  local errorRateRecordingRuleName = aggregationSet.getErrorRateMetricForBurnRate(burnRate);

  if errorRateRecordingRuleName != null then
    sliDefinition.generateErrorRateRecordingRules(
      burnRate=burnRate,
      recordingRuleName=errorRateRecordingRuleName,
      aggregationLabels=aggregationLabels,
      recordingRuleStaticLabels=recordingRuleStaticLabels
    )
  else
    [];

// Generates the recording rules given a component definition
local generateRecordingRulesForComponent(burnRate, aggregationSet, serviceDefinition, sliDefinition, aggregationLabels) =
  local recordingRuleStaticLabels = {
    tier: serviceDefinition.tier,
    type: serviceDefinition.type,
    component: sliDefinition.name,
  };

  std.flatMap(
    function(generator) generator(burnRate=burnRate, aggregationSet=aggregationSet, aggregationLabels=aggregationLabels, sliDefinition=sliDefinition, recordingRuleStaticLabels=recordingRuleStaticLabels),
    [
      generateApdexRules,
      generateRequestRateRules,
      generateErrorRateRules,
    ]
  );

{
  // This component metrics ruleset applies the key metrics recording rules for
  // each component in the metrics catalog
  componentMetricsRuleSetGenerator(
    burnRate,
    aggregationSet,
  )::
    {
      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        std.flatMap(
          function(sliDefinition) generateRecordingRulesForComponent(
            burnRate=burnRate,
            aggregationSet=aggregationSet,
            serviceDefinition=serviceDefinition,
            sliDefinition=sliDefinition,
            aggregationLabels=aggregationSet.labels,
          ),
          serviceDefinition.listServiceLevelIndicators()
        ),
    },

}
