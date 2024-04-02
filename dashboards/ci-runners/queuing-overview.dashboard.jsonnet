local layout = import 'grafana/layout.libsonnet';

local dashboardFilters = import 'stage-groups/verify-runner/dashboard_filters.libsonnet';
local dashboardHelpers = import 'stage-groups/verify-runner/dashboard_helpers.libsonnet';
local runnersManagerMatching = import 'stage-groups/verify-runner/runner_managers_matching.libsonnet';
local jobGraphs = import 'stage-groups/verify-runner/job_graphs.libsonnet';
local jobQueueGraphs = import 'stage-groups/verify-runner/job_queue_graphs.libsonnet';

dashboardHelpers.dashboard(
  'Jobs queuing overview',
  time_from='now-12h/m',
  includeRunnerManagerFilter=false,
)
.addTemplate(dashboardFilters.projectJobsRunning)
.addOverviewPanels()
.addGrid(
  startRow=2000,
  rowHeight=7,
  panels=[
    jobGraphs.running(['shard'], runnersManagerMatching.byShard),
    jobQueueGraphs.durationHistogram(partition=runnersManagerMatching.byShard),
    jobQueueGraphs.pendingSize,
  ],
)
.addGrid(
  startRow=3000,
  rowHeight=7,
  panels=[
    jobQueueGraphs.acceptableQueuingDurationExceeded(),
    jobQueueGraphs.queuingFailureRate(),
  ],
)
