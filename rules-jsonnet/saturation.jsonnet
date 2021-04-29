local saturationResources = import './saturation-resources.libsonnet';
local saturationRules = import 'servicemetrics/saturation_rules.libsonnet';

saturationRules.generateSaturationRules(dangerouslyThanosEvaluated=false, saturationResources=saturationResources)
