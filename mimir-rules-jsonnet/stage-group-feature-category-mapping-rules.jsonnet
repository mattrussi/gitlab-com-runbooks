local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local mappingGroups = import 'recording-rules/feature-category-mapping.libsonnet';

separateMimirRecordingFiles(
  function(service, selector, extraArgs)
    {
      'stage-group-feature-category-mapping': std.manifestYamlDoc({ groups: mappingGroups }),
    }
)
