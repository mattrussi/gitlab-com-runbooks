local recordingRules = import 'recording-rules/recording-rules.libsonnet';
local intervalForDuration = import 'servicemetrics/interval-for-duration.libsonnet';

local generateRecordingRules(sourceAggregationSet, targetAggregationSet, burnRates) =
  std.flatMap(
    function(burnRate)
      // Operation rate and Error Rate
      recordingRules.aggregationSetRateRuleSet(sourceAggregationSet=sourceAggregationSet, targetAggregationSet=targetAggregationSet, burnRate=burnRate)
      +
      // Error Ratio
      recordingRules.aggregationSetErrorRatioRuleSet(sourceAggregationSet=sourceAggregationSet, targetAggregationSet=targetAggregationSet, burnRate=burnRate)
      +
      // Apdex Score and Apdex Weight and Apdex SuccessRate
      recordingRules.aggregationSetApdexRatioRuleSet(sourceAggregationSet=sourceAggregationSet, targetAggregationSet=targetAggregationSet, burnRate=burnRate)
      +
      recordingRules.aggregationSetTransactionalRatesRuleSet(sourceAggregationSet=sourceAggregationSet, targetAggregationSet=targetAggregationSet, burnRate=burnRate),
    burnRates
  );

local groupForSetAndType(aggregationSet, burnType) =
  {
    name: '%s (%s burn)' % [aggregationSet.name, burnType],
    interval: intervalForDuration.intervalByBurnType[burnType],
  };

local generateRecordingRuleGroups(sourceAggregationSet, targetAggregationSet, extrasForGroup={}) =
  local burnRatesByType = targetAggregationSet.getBurnRatesByType();
  std.map(
    function(burnType)
      groupForSetAndType(targetAggregationSet, burnType) {
        rules: generateRecordingRules(sourceAggregationSet, targetAggregationSet, burnRatesByType[burnType]),
      } + extrasForGroup,
    std.objectFields(burnRatesByType)
  );

{
  /**
   * Generates a set of recording rules to aggregate from a source aggregation set to a target aggregation set
   */
  generateRecordingRuleGroups:: generateRecordingRuleGroups,
}
