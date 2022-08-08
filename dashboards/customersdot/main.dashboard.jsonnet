local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local row = grafana.row;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;

serviceDashboard.overview('customersdot')
.addPanel(
  row.new(title='⏱️  Stack Component Uptime'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 8,
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

    graphPanel.new(
      'Sidekiq - Queue Latency (in seconds)',
      formatY1='short',
      legend_values=true,
      legend_max=true,
      legend_min=false,
      legend_avg=true,
      legend_current=true,
      legend_alignAsTable=true,
      decimals=1,
    )
    .addTarget(
      prometheus.target(
        'rate(sidekiq_queue_latency_seconds{type="customersdot", environment="$environment"}[$__interval])',
        legendFormat='{{name}}'
      )
    ),

    graphPanel.new(
      'Sidekiq - Number of enqueued jobs',
      formatY1='short',
      legend_values=true,
      legend_max=true,
      legend_min=false,
      legend_avg=true,
      legend_current=true,
      legend_alignAsTable=true,
      decimals=1,
    )
    .addTarget(
      prometheus.target(
        'rate(sidekiq_queue_enqueued_jobs{type="customersdot", environment="$environment"}[$__interval])',
        legendFormat='{{name}}'
      )
    ),
  ]], [4, 4, 6, 6], rowHeight=8, startRow=1001)
)
.overviewTrailer()
