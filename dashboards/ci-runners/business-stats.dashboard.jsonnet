local dashboardHelpers = import 'stage-groups/verify-runner/dashboard_helpers.libsonnet';
local runnersManagerMatching = import 'stage-groups/verify-runner/runner_managers_matching.libsonnet';
local jobGraphs = import 'stage-groups/verify-runner/job_graphs.libsonnet';
local saturationGraphs = import 'stage-groups/verify-runner/saturation_graphs.libsonnet';

dashboardHelpers.dashboard(
  'Business metrics',
  time_from='now-14d',
  includeStandardEnvironmentAnnotations=false,
)
.addGrid(
  startRow=1000,
  rowHeight=5,
  panels=[
    jobGraphs.startedCounter(runnersManagerMatching.byShard),
  ],
)
.addGrid(
  startRow=2000,
  rowHeight=5,
  panels=[
    jobGraphs.finishedJobsMinutesIncreaseCounter(runnersManagerMatching.byShard),
  ],
)
.addGrid(
  startRow=3000,
  rowHeight=5,
  panels=[
    saturationGraphs.runnerSaturationCounter(runnersManagerMatching.byShard),
  ],
)
.addRowGrid(
  'Jobs started on runners',
  startRow=4000,
  collapse=true,
  panels=[
    jobGraphs.started(['shard'], runnersManagerMatching.byShard),
  ],
)
.addRowGrid(
  'Finised job minutes increase',
  startRow=4000,
  collapse=true,
  panels=[
    jobGraphs.finishedJobsMinutesIncrease(runnersManagerMatching.byShard),
  ],
)
.addRowGrid(
  'Finished job durations histogram',
  startRow=6000,
  collapse=true,
  panels=[
    jobGraphs.finishedJobsDurationHistogram(runnersManagerMatching.byShard),
  ],
)
