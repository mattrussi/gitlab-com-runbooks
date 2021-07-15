local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'service_dashboard.libsonnet';
local processExporter = import 'process_exporter.libsonnet';

serviceDashboard.overview('consul')
.addPanel(
  row.new(title='Clients'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.overviewTrailer()
