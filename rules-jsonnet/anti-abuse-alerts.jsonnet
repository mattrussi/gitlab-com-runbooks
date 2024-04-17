local alerts = import 'alerts/alerts.libsonnet';
local antiAbuseAlerts = import 'alerts/ci-runners-anti-abuse-alerts.libsonnet';

{
  'anti-abuse-alerts.yml': std.manifestYamlDoc(antiAbuseAlerts),
}
