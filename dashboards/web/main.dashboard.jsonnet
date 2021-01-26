local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local railsCommon = import 'rails_common_graphs.libsonnet';
local workhorseCommon = import 'workhorse_common_graphs.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'service_dashboard.libsonnet';

serviceDashboard.overview('web', 'sv')
.addPanel(
  row.new(title='Workhorse'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(workhorseCommon.workhorsePanels(serviceType='web', serviceStage='$stage', startRow=1001))
.addPanel(
  row.new(title='Rails'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(railsCommon.railsPanels(serviceType='web', serviceStage='$stage', startRow=3001))
.overviewTrailer()
