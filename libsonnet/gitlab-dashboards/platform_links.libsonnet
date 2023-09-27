local link = (import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet').link;
local serviceCatalog = import 'service-catalog/service-catalog.libsonnet';
local saturationResources = import '../servicemetrics/saturation-resources.libsonnet';
local grafana = import '../../metrics-catalog/saturation/grafana.libsonnet';

// These services do not yet have their own dashboards, remove from this list as they get their own dashboards
local USES_GENERIC_DASHBOARD = {
  pages: true,
};

local getServiceLink(serviceType) =
  if std.objectHas(USES_GENERIC_DASHBOARD, serviceType) then
    grafana.defaults.baseURL + '/general-service/service-platform-metrics?orgId=1&var-type=' + serviceType
  else
    grafana.defaults.baseURL + '/' + serviceCatalog.lookupService(serviceType).observability.monitors.primary_grafana_dashboard + '?orgId=1';

local getSaturationDetailLink(service, component) =
  local dashboard = grafana.resourceDashboard(service, saturationResources[component].grafana_dashboard_uid, component);
  {
    title: dashboard.name,
    url: dashboard.url,
  };

{
  triage:: [
    link.dashboards('Platform Triage', '', type='link', keepTime=true, url=grafana.defaults.baseURL + '/general-triage/platform-triage?orgId=1'),
  ],
  services:: [
    link.dashboards(
      title='Service Overview Dashboards',
      tags=[
        'managed',
        'service overview',
      ],
      asDropdown=true,
      includeVars=true,
      keepTime=true,
      type='dashboards',
    ),
  ],
  backToOverview(type)::
    link.dashboards('🔙 Back to ' + type + ' service', '', type='link', keepTime=true, url=getServiceLink(type)),

  kubenetesDetail(type)::
    link.dashboards(
      title='☸️ %s Kubernetes Detail' % [type],
      tags=[
        'managed',
        'type:' + type,
        'kube detail',
      ],
      asDropdown=true,
      includeVars=true,
      keepTime=true,
      type='dashboards',
    ),
  parameterizedServiceLink: [
    link.dashboards('$type service', '', type='link', keepTime=true, url=grafana.defaults.baseURL + '/general-service/service-platform-metrics?orgId=1&var-type=$type'),
  ],
  serviceLink(type):: [
    link.dashboards(type + ' service', '', type='link', keepTime=true, url=getServiceLink(type)),
  ],
  saturationDetails(type)::
    std.map(
      function(resource) getSaturationDetailLink(type, resource),
      saturationResources.listApplicableServicesFor(type)
    )
  ,
  dynamicLinks(title, tags, asDropdown=true, icon='dashboard', includeVars=true, keepTime=true)::
    link.dashboards(
      title,
      tags,
      asDropdown=asDropdown,
      includeVars=includeVars,
      keepTime=keepTime,
      icon=icon,
    ),
}
