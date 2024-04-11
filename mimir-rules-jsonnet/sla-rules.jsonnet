local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local rules = import 'recording-rules/sla-rules.libsonnet';

separateMimirRecordingFiles(
  function(_, selector, _)
    {
      'sla-rules': std.manifestYamlDoc(
        rules.slaRules(
          selector,
          sloObservationStatusMetric='slo_observation_status',
        )
      ),
    } + {
      // The SLA is the same for all environments, no need to have separate files
      'sla-target': std.manifestYamlDoc(
        rules.slaTargetRules()
      ),
    }
)
