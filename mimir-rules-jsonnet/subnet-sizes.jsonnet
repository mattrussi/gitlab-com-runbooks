local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local subnetSizes = import 'recording-rules/subnet-sizes.libsonnet';

// We're only recording this for 'gprd' with a static label.
// No need to separate this by environment

separateMimirRecordingFiles(
  function(service, selector, extraArgs)
    {
      'subnet-sizes': std.manifestYamlDoc({ groups: subnetSizes }),
    }
)
