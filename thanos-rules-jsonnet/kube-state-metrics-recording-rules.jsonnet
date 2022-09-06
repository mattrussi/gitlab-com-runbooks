local groups = import 'kube-state-metrics/recording-rules.libsonnet';

{
  'kube-state-metrics-recording-rules.yml': std.manifestYamlDoc({
    groups: std.map(function(g) g { partial_response_strategy: 'warn' }, groups.thanos),
  }),
}
