local metricsConfig = import 'gitlab-metrics-config.libsonnet';
local rules = import 'recording-rules/stage-group-monthly-availability.libsonnet';
local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;

separateMimirRecordingFiles(
  function(service, selector, extraArgs, _)
    {
      'stage-group-monthly-availability': std.manifestYamlDoc(rules()),
    },
  overrideTenants=metricsConfig.stageGroupTenants
)
