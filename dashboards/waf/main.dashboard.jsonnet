local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';

local environmentSelector = { env: 'ops', environment: 'ops' };

serviceDashboard.overview(
  'waf',
  environmentSelectorHash=environmentSelector,
  saturationEnvironmentSelectorHash=environmentSelector,
)
.overviewTrailer()
