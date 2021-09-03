{
  aggregationSetApdexRatioRuleSet: (import 'aggregation-set-apdex-ratio-rule-set.libsonnet').aggregationSetApdexRatioRuleSet,
  aggregationSetErrorRatioRuleSet: (import 'aggregation-set-error-ratio-rule-set.libsonnet').aggregationSetErrorRatioRuleSet,
  aggregationSetRateRuleSet: (import 'aggregation-set-rate-rule-set.libsonnet').aggregationSetRateRuleSet,
  componentMappingRuleSetGenerator: (import 'component-mapping-rule-set-generator.libsonnet').componentMappingRuleSetGenerator,
  componentMetricsRuleSetGenerator: (import 'component-metrics-rule-set-generator.libsonnet').componentMetricsRuleSetGenerator,
  componentNodeSLORuleSetGenerator: (import 'component-node-slo-rule-set-generator.libsonnet').componentNodeSLORuleSetGenerator,
  extraRecordingRuleSetGenerator: (import 'extra-recording-rule-set-generator.libsonnet').extraRecordingRuleSetGenerator,
  serviceMappingRuleSetGenerator: (import 'service-mapping-rule-set-generator.libsonnet').serviceMappingRuleSetGenerator,
  serviceSLORuleSetGenerator: (import 'service-slo-rule-set-generator.libsonnet').serviceSLORuleSetGenerator,
  sliRecordingRulesSetGenerator: (import 'sli-recording-rule-set-generator.libsonnet').sliRecordingRulesSetGenerator,
  sliUpscaledRecordingRulesSetGenerator: (import 'sli-upscaled-recording-rule-set-generator.libsonnet').sliUpscaledRecordingRulesSetGenerator,
  thresholdHealthRuleSet(threshold): (import 'mwmbr-threshold-health-rule-set.libsonnet').thresholdHealthRuleSet(threshold),
}
