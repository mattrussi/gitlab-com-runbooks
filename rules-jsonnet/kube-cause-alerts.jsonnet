local kubeCauseAlerts = import 'alerts/kube-cause-alerts.libsonnet';

{
  'kube-cause-alerts.yml': std.manifestYamlDoc(kubeCauseAlerts()),
}
