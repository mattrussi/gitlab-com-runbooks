local saturationResources = import 'servicemetrics/saturation-resources.libsonnet';
local saturationRules = import 'servicemetrics/saturation_rules.libsonnet';

saturationRules.generateSaturationRules(
  includePrometheusEvaluated=false,
  includeDangerouslyThanosEvaluated=true,
  saturationResources=saturationResources
)
