// Generates apdex weight recording rules for a component definition
local generateApdexRules(burnRate, recordingRuleNames, aggregationLabels, sliDefinition, recordingRuleStaticLabels) =
  if recordingRuleNames.apdexSuccessRate != null || recordingRuleNames.apdexWeight != null then
    sliDefinition.generateApdexRecordingRules(
      burnRate=burnRate,
      recordingRuleNames=recordingRuleNames,
      aggregationLabels=aggregationLabels,
      recordingRuleStaticLabels=recordingRuleStaticLabels
    )
  else
    [];

local generateRequestRateRules(burnRate, recordingRuleNames, aggregationLabels, sliDefinition, recordingRuleStaticLabels) =
  // All components have a requestRate metric
  if recordingRuleNames.requestRate != null then
    sliDefinition.generateRequestRateRecordingRules(
      burnRate=burnRate,
      recordingRuleName=recordingRuleNames.requestRate,
      aggregationLabels=aggregationLabels,
      recordingRuleStaticLabels=recordingRuleStaticLabels
    )
  else
    [];

local generateErrorRateRules(burnRate, recordingRuleNames, aggregationLabels, sliDefinition, recordingRuleStaticLabels) =
  if recordingRuleNames.errorRate != null then
    sliDefinition.generateErrorRateRecordingRules(
      burnRate=burnRate,
      recordingRuleName=recordingRuleNames.errorRate,
      aggregationLabels=aggregationLabels,
      recordingRuleStaticLabels=recordingRuleStaticLabels
    )
  else
    [];

// Generates the recording rules given a component definition
local generateRecordingRulesForComponent(burnRate, recordingRuleNames, serviceDefinition, sliDefinition, aggregationLabels) =
  local recordingRuleStaticLabels = {
    tier: serviceDefinition.tier,
    type: serviceDefinition.type,
    component: sliDefinition.name,
  };

  std.flatMap(
    function(generator) generator(burnRate=burnRate, recordingRuleNames=recordingRuleNames, aggregationLabels=aggregationLabels, sliDefinition=sliDefinition, recordingRuleStaticLabels=recordingRuleStaticLabels),
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
    local recordingRuleNames = {
      apdexSuccessRate: aggregationSet.getApdexSuccessRateMetricForBurnRate(burnRate),
      apdexWeight: aggregationSet.getApdexWeightMetricForBurnRate(burnRate),
      requestRate: aggregationSet.getOpsRateMetricForBurnRate(burnRate),
      errorRate: aggregationSet.getErrorRateMetricForBurnRate(burnRate),
    };

    {
      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        std.flatMap(
          function(sliDefinition) generateRecordingRulesForComponent(
            burnRate=burnRate,
            recordingRuleNames=recordingRuleNames,
            serviceDefinition=serviceDefinition,
            sliDefinition=sliDefinition,
            aggregationLabels=aggregationSet.labels,
          ),
          serviceDefinition.listServiceLevelIndicators()
        ),
    },

}
