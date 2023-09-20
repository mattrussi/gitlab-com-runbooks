local saturationResources = import 'servicemetrics/saturation-resources.libsonnet';
local saturationRules = import 'servicemetrics/saturation_rules.libsonnet';
local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;

local filesForSeparateSelector(selector) = {
  saturation:
    std.manifestYamlDoc({
      groups:
        // Thanos Evaluated Services
        saturationRules.generateSaturationRulesGroup(
          saturationResources=saturationResources,
          extraSourceSelector=selector,
          evaluation='thanos-staging',
        )
        +
        // Alerts and long range quantiles
        saturationRules.generateSaturationAuxRulesGroup(
          saturationResources=saturationResources,
          extraSelector=selector,
          evaluation='thanos-staging',
          thanosSelfMonitoring=false,
        ),
    }),
};

separateGlobalRecordingFiles(filesForSeparateSelector) {
  // SLOs and metadata are the same across environments
  'saturation-metadata.yml': std.manifestYamlDoc({
    groups: saturationRules.generateSaturationMetadataRulesGroup(
      saturationResources=saturationResources,
      evaluation='thanos-staging',
      thanosSelfMonitoring=false,
    ),
  }),

  'thanos-self-monitoring-saturation.yml': std.manifestYamlDoc({
    groups:
      saturationRules.generateSaturationRulesGroup(
        saturationResources=saturationResources,
        extraSourceSelector={ env: 'ops' },
        evaluation='thanos-staging',
        thanosSelfMonitoring=true,
        staticLabels={
          env: 'thanos-staging',
          environment: 'thanos-staging',
          stage: 'main',
          tier: 'inf',
        },
      ) +
      // Alerts and long range quantiles
      saturationRules.generateSaturationAuxRulesGroup(
        saturationResources=saturationResources,
        // Only generate alerts for thanos here, the others evaluated in thanos
        // will be part of the environment specific files
        extraSelector={ type: 'thanos-staging' },
        evaluation='thanos-staging',
        thanosSelfMonitoring=true,
      ),
  }),

}
