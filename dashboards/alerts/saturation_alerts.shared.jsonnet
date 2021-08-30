local saturationAlerts = import 'gitlab-monitoring/alerts/saturation_alerts.libsonnet';
local saturationResources = import 'gitlab-monitoring/servicemetrics/saturation-resources.libsonnet';

{
  [saturationResources[key].grafana_dashboard_uid]:
    saturationAlerts.saturationDashboardForComponent(key)
  for key in std.objectFields(saturationResources)
}
