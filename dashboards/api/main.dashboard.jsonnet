local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local railsCommon = import 'gitlab-dashboards/rails_common_graphs.libsonnet';
local workhorseCommon = import 'gitlab-dashboards/workhorse_common_graphs.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';

local useTimeSeriesPlugin = true;

serviceDashboard.overview('api')
.addPanel(
  row.new(title='Workhorse'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(workhorseCommon.workhorsePanels(serviceType='api', serviceStage='$stage', startRow=1001, useTimeSeriesPlugin=useTimeSeriesPlugin))
.addPanel(
  row.new(title='Rails'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(railsCommon.railsPanels(serviceType='api', serviceStage='$stage', startRow=3001, useTimeSeriesPlugin=useTimeSeriesPlugin))
.overviewTrailer()
