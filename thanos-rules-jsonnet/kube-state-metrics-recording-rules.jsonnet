local recordingRules = import 'kube-state-metrics/recording-rules.libsonnet';
local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;

separateGlobalRecordingFiles(
  function(selector)
    {
      'kube-state-metrics-recording-rules': std.manifestYamlDoc({
        groups:
          std.map(
            function(group)
              group { partial_response_strategy: 'warn' },
            recordingRules.groupsWithFilter(function(service) service.dangerouslyThanosEvaluated, selector)
          ),
      }),
    },
)
