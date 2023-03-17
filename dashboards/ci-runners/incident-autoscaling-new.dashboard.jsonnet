local autoscalingGraphs = import 'stage-groups/verify-runner/autoscaling_graphs.libsonnet';
local dashboardFilters = import 'stage-groups/verify-runner/dashboard_filters.libsonnet';
local dashboardIncident = import 'stage-groups/verify-runner/dashboard_incident.libsonnet';
local fleetingGraphs = import 'stage-groups/verify-runner/fleeting_graphs.libsonnet';

dashboardIncident.incidentDashboard(
  'autoscaling-new',
  'as',
  description=|||
    In short: problems with autoscaling will reduce (even totally) the capacity of our Runners.

    **It's recommended to review the graphs after limiting the shard variable to only
    the part of Runners that we want to analyse.** Otherwise the number of different lines
    may be overwhelming. Please also remember that **different shards have different autosacling
    settings**, where the `shared` one is the most outstanding at it creates a VM dedicated for
    every job and removes it just after the job is finished.

    **We're currently in the process of moving to a new autoscaling mechanism.** For now there are no
    known guidelines as to how to work with it and what to review in case of troubles. We will be
    udpating this description after getting some more experience with using that new method.
  |||,
)
.addGrid(
  panels=[
    fleetingGraphs.taskscalerTasksSaturation,
    fleetingGraphs.provisionerInstancesSaturation,
  ],
  rowHeight=6,
  startRow=3000,
)
.addGrid(
  panels=[
    fleetingGraphs.provisionerInstancesStates,
    fleetingGraphs.provisionerMissedUpdates,
    fleetingGraphs.provisionerCreationTiming,
    fleetingGraphs.provisionerIsRunningTiming,
    fleetingGraphs.provisionerDeletionTiming,
  ],
  rowHeight=8,
  startRow=4000,
)
.addGrid(
  panels=[
    fleetingGraphs.taskscalerOperationsRate,
    fleetingGraphs.taskscalerTasks,
    fleetingGraphs.taskscalerInstanceReadinessTiming,
  ],
  rowHeight=8,
  startRow=5000,
)
