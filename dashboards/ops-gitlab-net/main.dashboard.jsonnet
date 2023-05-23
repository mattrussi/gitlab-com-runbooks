local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';

serviceDashboard.overview(
  'ops-gitlab-net',
  showProvisioningDetails=false,
  showSystemDiagrams=false,
  environmentSelectorHash={},
  saturationEnvironmentSelectorHash={},
)
.overviewTrailer()
