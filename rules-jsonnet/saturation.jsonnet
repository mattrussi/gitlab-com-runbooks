local saturationResources = import 'gitlab-monitoring/servicemetrics/saturation-resources.libsonnet';
local saturationRules = import 'gitlab-monitoring/servicemetrics/saturation_rules.libsonnet';

saturationRules.generateSaturationRules(dangerouslyThanosEvaluated=false, saturationResources=saturationResources)
