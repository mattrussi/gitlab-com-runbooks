local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';

local environmentSelector = { env: 'ops', environment: 'ops' };

serviceDashboard.overview(
  'ops-gitlab-net',
  showProvisioningDetails=false,
  showSystemDiagrams=false,
  environmentSelectorHash=environmentSelector,
  saturationEnvironmentSelectorHash=environmentSelector,
)
.overviewTrailer()
