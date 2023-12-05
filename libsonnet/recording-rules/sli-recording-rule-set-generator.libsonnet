local generateRecordingRulesForMetric(recordingRuleMetric, burnRate, recordingRuleRegistry, aggregateAllSourceMetrics, extraSelector) =
  if aggregateAllSourceMetrics || recordingRuleRegistry.recordingRuleForMetricAtBurnRate(metricName=recordingRuleMetric, rangeInterval=burnRate) then
    local expression = recordingRuleRegistry.recordingRuleExpressionFor(metricName=recordingRuleMetric, rangeInterval=burnRate, extraSelector=extraSelector);
    local recordingRuleName = recordingRuleRegistry.recordingRuleNameFor(metricName=recordingRuleMetric, rangeInterval=burnRate);

    [{
      record: recordingRuleName,
      expr: expression,
    }]
  else
    [];

{
  // This generates recording rules for metrics with high-cardinality
  // that are specified in the service catalog under the
  // `recordingRuleMetrics` attribute.
  sliRecordingRulesSetGenerator(
    burnRate,
    recordingRuleRegistry,
    aggregateAllSourceMetrics,
    extraSelector
  )::
    {
      burnRate: burnRate,

      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        local metrics = if aggregateAllSourceMetrics then
          std.flatMap(
            function(sli) sli.recordingRuleMetrics,
            serviceDefinition.listServiceLevelIndicators(),
          )
        else
          std.get(serviceDefinition, 'recordingRuleMetrics', default=[]);

        std.flatMap(
          function(recordingRuleMetric) generateRecordingRulesForMetric(
            recordingRuleMetric, burnRate, recordingRuleRegistry, aggregateAllSourceMetrics, extraSelector
          ),
          metrics,
        ),
    },

}
