local patroniCauseAlerts = import 'alerts/patroni-cause-alerts.libsonnet';

{
  'patroni-cause-alerts.yml': std.manifestYamlDoc(patroniCauseAlerts()),
}
