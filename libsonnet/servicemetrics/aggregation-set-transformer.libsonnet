local recordingRules = import 'recording-rules/recording-rules.libsonnet';

local generateRecordingRules(sourceAggregationSet, targetAggregationSet) =
  local burnRates = targetAggregationSet.getBurnRates();

  std.flatMap(
    function(burnRate)
      // Operation rate and Error Rate
      recordingRules.aggregationSetRateRuleSet(sourceAggregationSet=sourceAggregationSet, targetAggregationSet=targetAggregationSet, burnRate=burnRate)
      +
      // Error Ratio
      recordingRules.aggregationSetErrorRatioRuleSet(sourceAggregationSet=sourceAggregationSet, targetAggregationSet=targetAggregationSet, burnRate=burnRate)
      +
      // Apdex Score and Apdex Weight and Apdex SuccessRate
      recordingRules.aggregationSetApdexRatioRuleSet(sourceAggregationSet=sourceAggregationSet, targetAggregationSet=targetAggregationSet, burnRate=burnRate),
    burnRates
  );

local generateRatioRecordingRules(aggregationSet) =
  local burnRates = aggregationSet.getBurnRates();

  std.flatMap(
    function(burnRate)
      // Error Ratio
      recordingRules.aggregationSetErrorRatioRuleSet(sourceAggregationSet=aggregationSet, targetAggregationSet=aggregationSet, burnRate=burnRate)
      +
      // Apdex Score and Apdex Weight and Apdex SuccessRate
      recordingRules.aggregationSetApdexRatioRuleSet(sourceAggregationSet=aggregationSet, targetAggregationSet=aggregationSet, burnRate=burnRate),
    burnRates
  );

{
  /**
   * Generates a set of recording rules to aggregate from a source aggregation set to a target aggregation set
   */
  generateRecordingRules:: generateRecordingRules,

  /**
   * In Prometheus-only environments, we need to perform ratio recording rules in Prometheus
   * This function will generate recording rules to handle generation of ratios for a aggregation set
   */
  generateRatioRecordingRules:: generateRatioRecordingRules,

}
