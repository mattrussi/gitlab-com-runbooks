local recordingRules = import 'recording-rules/recording-rules.libsonnet';

local generateRecordingRules(sourceAggregationSet, targetAggregationSet) =
  local burnRates = sourceAggregationSet.getCommonBurnRates(targetAggregationSet);

  std.flatMap(
    function(burnRate)
      // Operation rate and Error Rate
      recordingRules.aggregationSetRateRuleSet(sourceAggregationSet=sourceAggregationSet, targetAggregationSet=targetAggregationSet, burnRate=burnRate)
      +
      // Error Ratio
      recordingRules.aggregationSetErrorRatioRuleSet(aggregationSet=targetAggregationSet, burnRate=burnRate)
      +
      // Apdex Score and Apdex Weight
      recordingRules.aggregationSetApdexRatioRuleSet(sourceAggregationSet=sourceAggregationSet, targetAggregationSet=targetAggregationSet, burnRate=burnRate),
    burnRates
  );

{
  /**
   * Generates a set of recording rules to aggregate from a source aggregation set to a target aggregation set
   */
  generateRecordingRules:: generateRecordingRules,
}
