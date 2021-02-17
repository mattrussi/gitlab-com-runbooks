local kubeDashboards = import 'kube_service_dashboards.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local regionalDashboards = import 'regional_service_dashboard.libsonnet';

local forService(serviceType) =
  local serviceInfo = metricsCatalog.getService(serviceType);

  {}
  +
  (
    if serviceInfo.regional then
      { regional: regionalDashboards.dashboardForService(serviceType) }
    else
      {}
  )
  +
  (
    if std.length(serviceInfo.kubeResources) > 0 then
      kubeDashboards.dashboardsForService(serviceType)
    else
      {}
  );

{
  forService:: forService,
}
