local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'service_dashboard.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';

serviceDashboard.overview('kas')
.addPanel(
  row.new(title='Kubernetes Agent'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title="Number of connected agentk's",
      description='Number of connected agentk from user Kubernetes clusters',
      query='sum(grpc_server_requests_in_flight{app="kas",env=~"$environment", grpc_method="GetConfiguration"})',
      interval='1m',
      intervalFactor=2,
      legendFormat='Count',
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
  ], cols=1, rowHeight=10, startRow=1001)
)
.overviewTrailer()
