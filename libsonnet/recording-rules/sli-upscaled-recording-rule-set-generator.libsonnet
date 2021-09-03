local intervalForDuration = import 'servicemetrics/interval-for-duration.libsonnet';

local generateRecordingRulesForMetric(recordingRuleMetric, burnRate, recordingRuleRegistry) =
  if recordingRuleRegistry.upscaledRecordingRuleForMetricAtBurnRate(metricName=recordingRuleMetric, rangeInterval=burnRate) then
    local upscaleInterval = '1h';
    local upscaleExpression = recordingRuleRegistry.recordingRuleNameFor(metricName=recordingRuleMetric, rangeInterval=upscaleInterval);
    local expression = recordingRuleRegistry.upscaledRecordingRuleExpressionFor(expression=upscaleExpression, recordingRuleInterval=intervalForDuration.intervalForDuration(upscaleInterval), rangeInterval=burnRate);
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
  sliUpscaledRecordingRulesSetGenerator(
    burnRate,
    recordingRuleRegistry,
  )::
    {
      burnRate: burnRate,

      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        if std.objectHas(serviceDefinition, 'recordingRuleMetrics') then
          std.flatMap(
            function(recordingRuleMetric) generateRecordingRulesForMetric(recordingRuleMetric, burnRate, recordingRuleRegistry),
            serviceDefinition.recordingRuleMetrics
          )
        else
          [],
    },

}
