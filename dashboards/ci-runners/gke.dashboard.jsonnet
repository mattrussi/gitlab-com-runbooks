local dashboardFilters = import 'stage-groups/verify-runner/dashboard_filters.libsonnet';
local dashboardHelpers = import 'stage-groups/verify-runner/dashboard_helpers.libsonnet';
local gkeGraphs = import 'stage-groups/verify-runner/gke_graphs.libsonnet';

dashboardHelpers.dashboard(
  'GKE',
  time_from='now-3h',
  includeStandardEnvironmentAnnotations=false,
  includeCommonFilters=false,
)
.addTemplate(dashboardFilters.ciEnvironment)
.addRowGrid(
  'Node metrics',
  startRow=1,
  collapse=false,
  panels=[
    gkeGraphs.cpuUsage,
    gkeGraphs.memoryUsage,
    gkeGraphs.diskAvailable,
    gkeGraphs.iopsUtilization,
  ],
)
