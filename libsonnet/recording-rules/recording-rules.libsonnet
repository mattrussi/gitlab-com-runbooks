{

  aggregationSetApdexRatioRuleSet: (import 'aggregation-set-apdex-ratio-rule-set.libsonnet').aggregationSetApdexRatioRuleSet,
  aggregationSetErrorRatioRuleSet: (import 'aggregation-set-error-ratio-rule-set.libsonnet').aggregationSetErrorRatioRuleSet,
  aggregationSetRateRuleSet: (import 'aggregation-set-rate-rule-set.libsonnet').aggregationSetRateRuleSet,

  aggregationSetTransactionalRatesRuleSet: (import './transactional-rates/transactional-rates.libsonnet').aggregationSetRuleSet,

  componentMappingRuleSetGenerator: (import 'component-mapping-rule-set-generator.libsonnet').componentMappingRuleSetGenerator,
  componentMetricsRuleSetGenerator: (import 'component-metrics-rule-set-generator.libsonnet').componentMetricsRuleSetGenerator,
  extraRecordingRuleSetGenerator: (import 'extra-recording-rule-set-generator.libsonnet').extraRecordingRuleSetGenerator,
  serviceMappingRuleSetGenerator: (import 'service-mapping-rule-set-generator.libsonnet').serviceMappingRuleSetGenerator,
  serviceSLORuleSetGenerator: (import 'service-slo-rule-set-generator.libsonnet').serviceSLORuleSetGenerator,
  sliRecordingRulesSetGenerator: (import 'sli-recording-rule-set-generator.libsonnet').sliRecordingRulesSetGenerator,
  thresholdHealthRuleSet: (import 'mwmbr-threshold-health-rule-set.libsonnet').thresholdHealthRuleSet,

  errorRatioConfidenceInterval: (import 'confidence-interval-generators.libsonnet').errorRatioConfidenceInterval,
  apdexRatioConfidenceInterval: (import 'confidence-interval-generators.libsonnet').apdexRatioConfidenceInterval,
}
