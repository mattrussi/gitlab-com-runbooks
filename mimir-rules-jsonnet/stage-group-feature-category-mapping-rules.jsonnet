local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local mappingGroups = import 'recording-rules/feature-category-mapping.libsonnet';
local metricsConfig = import 'gitlab-metrics-config.libsonnet';

separateMimirRecordingFiles(
  function(service, selector, extraArgs, _)
    {
      'stage-group-feature-category-mapping': std.manifestYamlDoc({ groups: mappingGroups }),
    },
  overrideTenants=metricsConfig.stageGroupTenants
)
