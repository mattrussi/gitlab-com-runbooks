local recordingRules = import 'kube-state-metrics/recording-rules.libsonnet';
local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;

separateGlobalRecordingFiles(
  function(selector)
    {
      'kube-state-metrics-recording-rules.yml': std.manifestYamlDoc({
        groups:
          std.map(
            function(group)
              group,
            recordingRules.groupsWithFilter(function(service) service.dangerouslyThanosEvaluated, selector)
          ),
      }),
    },
  pathFormat='%(envName)s/%(baseName)s'
)
