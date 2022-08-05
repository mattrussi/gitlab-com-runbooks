local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local row = grafana.row;

serviceDashboard.overview('customersdot')
.addPanel(
  row.new(title='⏱️  Stack Component Uptime'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 6,
  }
)
.addPanels(
  layout.columnGrid([[
    basic.slaStats(
      title='CustomersDot probe result',
      query='avg(avg_over_time(probe_success{environment="$environment"}[$__interval]))'
    ),
    basic.slaStats(
      title='Puma uptime',
      query='1-(avg(avg_over_time(last_scrape_error{environment="$environment"}[$__interval])))',
    ),
    basic.slaStats(
      title='Sidekiq worker availability',
      query='(sum(avg_over_time(sidekiq_workers{environment="$environment"}[$__interval])) / 5)'
    ),
  ]], [4, 4, 4], rowHeight=5, startRow=1001)
)
.overviewTrailer()
