local recordingRules = import 'kube-state-metrics/recording-rules.libsonnet';

{
  'kube-state-metrics-recording-rules.yml': std.manifestYamlDoc({
    groups: recordingRules.groupsWithFilter(
      function(service)
        !service.dangerouslyThanosEvaluated
    ),
  }),
}
