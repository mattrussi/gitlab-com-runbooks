local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

local stageGroupDashboards = import './stage-group-dashboards.libsonnet';

local actionCableActiveConnections() =
  basic.timeseries(
    stableId='action_cable_active_connections',
    title='ActionCable Active Connections',
    decimals=2,
    yAxisLabel='Connections',
    description=|||
      Number of ActionCable connections active at the time of sampling.
    |||,
    query=|||
      sum(
        action_cable_active_connections{
          environment="$environment",
          stage="$stage",
        }
      )
    |||,
  );

stageGroupDashboards
.dashboard('project_management')
.addPanels(
  layout.rowGrid(
    'ActionCable Connections',
    [
      actionCableActiveConnections(),
    ],
    startRow=1101
  ),
)
.stageGroupDashboardTrailer()
