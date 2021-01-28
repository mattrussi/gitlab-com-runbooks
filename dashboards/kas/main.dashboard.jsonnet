local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'service_dashboard.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';

serviceDashboard.overview('kas', 'sv')
.addPanel(
  row.new(title='Kubernetes Agent'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
