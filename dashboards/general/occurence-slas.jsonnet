local generalServicesDashboard = import './general-services-dashboard.libsonnet';
local occurenceSLADashboard = import 'gitlab-dashboards/occurrence-sla-dashboard.libsonnet';
local metricsConfig = import 'gitlab-metrics-config.libsonnet';

local sortedServices = std.map(function(service) service.name, generalServicesDashboard.sortedKeyServices(includeZeroScore=false));

occurenceSLADashboard.dashboard(
  sortedServices,
  metricsConfig.aggregationSets.serviceSLIs,
  { stage: 'main', environment: '$environment', monitor: 'global' }
)
