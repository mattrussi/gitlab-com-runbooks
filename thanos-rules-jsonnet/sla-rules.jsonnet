local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;
local rules = import 'recording-rules/sla-rules.libsonnet';

separateGlobalRecordingFiles(
  function(selector)
    {
      'sla-rules': std.manifestYamlDoc(
        rules.slaRules(
          selector,
          sloObservationStatusMetric='slo_observation_status',
          groupExtras={ partial_response_strategy: 'warn' }
        )
      ),
    }
) + {
  // The SLA is the same for all environments, no need to have separate files
  'sla-target.yml': std.manifestYamlDoc(
    rules.slaTargetRules(groupExtras={ partial_response_strategy: 'warn' })
  ),
}
