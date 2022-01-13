local recordingRules = import 'recording-rules/recording-rules.libsonnet';

local generateRecordingRules(sourceAggregationSet, targetAggregationSet, burnRates=targetAggregationSet.getBurnRates()) =
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

local generateReflectedRecordingRules(aggregationSet, burnRates=aggregationSet.getBurnRates()) =
  std.flatMap(
    function(burnRate)
      // Error Ratio
      recordingRules.aggregationSetErrorRatioReflectedRuleSet(aggregationSet=aggregationSet, burnRate=burnRate)
      +
      // Apdex Score and Apdex Weight and Apdex SuccessRate
      recordingRules.aggregationSetApdexRatioReflectedRuleSet(aggregationSet=aggregationSet, burnRate=burnRate),
    burnRates
  );

{
  /**
   * Generates a set of recording rules to aggregate from a source aggregation set to a target aggregation set
   */
  generateRecordingRules:: generateRecordingRules,

  /**
   * When using Prometheus without Thanos, some recording rules are generated from the same
   * aggregation set -- specifically error ratios and apdex ratios. These recording rules
   * should not be used in two-tier aggregation sets.
   */
  generateReflectedRecordingRules:: generateReflectedRecordingRules,

}
