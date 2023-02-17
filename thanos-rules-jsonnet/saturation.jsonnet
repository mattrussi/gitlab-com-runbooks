local saturationResources = import 'servicemetrics/saturation-resources.libsonnet';
local saturationRules = import 'servicemetrics/saturation_rules.libsonnet';

local includePrometheusEvaluated = false;
local includeDangerouslyThanosEvaluated = true;

{
  'saturation.yml':
    std.manifestYamlDoc({
      groups:
        // Thanos Evaluated Services
        saturationRules.generateSaturationRulesGroup(
          saturationResources=saturationResources,
          includePrometheusEvaluated=includePrometheusEvaluated,
          includeDangerouslyThanosEvaluated=includeDangerouslyThanosEvaluated,
        )
        +
        // Thanos Self-Monitoring
        saturationRules.generateSaturationRulesGroup(
          saturationResources=saturationResources,
          includePrometheusEvaluated=includePrometheusEvaluated,
          includeDangerouslyThanosEvaluated=includeDangerouslyThanosEvaluated,
          thanosSelfMonitoring=true,
          staticLabels={
            env: 'thanos',
            environment: 'thanos',
            stage: 'main',
            tier: 'inf',
          },
        )
        +
        // Metadata + Alerts
        saturationRules.generateSaturationAuxRulesGroup(
          saturationResources=saturationResources,
          includePrometheusEvaluated=includePrometheusEvaluated,
          includeDangerouslyThanosEvaluated=includeDangerouslyThanosEvaluated,
        ),
    }),
}
