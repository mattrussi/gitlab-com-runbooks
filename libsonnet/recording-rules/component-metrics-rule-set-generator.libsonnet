// Generates apdex weight recording rules for a component definition
local generateApdexWeightRules(burnRate, recordingRuleNames, aggregationLabels, sliDefinition, recordingRuleStaticLabels) =
  if recordingRuleNames.apdexWeight != null then
    sliDefinition.generateApdexWeightRecordingRules(
      burnRate=burnRate,
      recordingRuleName=recordingRuleNames.apdexWeight,
      aggregationLabels=aggregationLabels,
      recordingRuleStaticLabels=recordingRuleStaticLabels
    )
  else
    [];

// Generates a curryable function to apdex score recording rules for a component definition
local generateApdexScoreRulesCurry(substituteWeightWithRecordingRule) =
  function(burnRate, recordingRuleNames, aggregationLabels, sliDefinition, recordingRuleStaticLabels)
    if recordingRuleNames.apdexRatio != null then
      sliDefinition.generateApdexScoreRecordingRules(
        burnRate=burnRate,
        recordingRuleName=recordingRuleNames.apdexRatio,
        aggregationLabels=aggregationLabels,
        recordingRuleStaticLabels=recordingRuleStaticLabels,
        substituteWeightWithRecordingRuleName=if substituteWeightWithRecordingRule then recordingRuleNames.apdexWeight else null
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
local generateRecordingRulesForComponent(burnRate, recordingRuleNames, serviceDefinition, sliDefinition, aggregationLabels, substituteWeightWithRecordingRule) =
  local recordingRuleStaticLabels = {
    type: serviceDefinition.type,
    component: sliDefinition.name,
  };

  std.flatMap(
    function(generator) generator(burnRate=burnRate, recordingRuleNames=recordingRuleNames, aggregationLabels=aggregationLabels, sliDefinition=sliDefinition, recordingRuleStaticLabels=recordingRuleStaticLabels),
    [
      generateApdexWeightRules,
      generateApdexScoreRulesCurry(substituteWeightWithRecordingRule),
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
    substituteWeightWithRecordingRule=false,
  )::
    local recordingRuleNames = {
      apdexRatio: aggregationSet.getApdexRatioMetricForBurnRate(burnRate),
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
            substituteWeightWithRecordingRule=substituteWeightWithRecordingRule
          ),
          serviceDefinition.listServiceLevelIndicators()
        ),
    },

}
