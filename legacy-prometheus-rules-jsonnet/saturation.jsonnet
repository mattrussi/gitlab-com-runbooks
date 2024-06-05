local saturationResources = import 'servicemetrics/saturation-resources.libsonnet';
local saturationRules = import 'servicemetrics/saturation_rules.libsonnet';

local includePrometheusEvaluated = true;
local includeDangerouslyThanosEvaluated = false;

{
  'saturation.yml':
    std.manifestYamlDoc({
      groups:
        saturationRules.generateSaturationRulesGroup(
          saturationResources=saturationResources,
          evaluation='prometheus'
        )
        +
        saturationRules.generateSaturationMetadataRulesGroup(
          saturationResources=saturationResources,
          evaluation='prometheus'
        )
        +
        // Metadata + Alerts
        saturationRules.generateSaturationAuxRulesGroup(
          saturationResources=saturationResources,
          evaluation='prometheus'
        ),
    }),
}
