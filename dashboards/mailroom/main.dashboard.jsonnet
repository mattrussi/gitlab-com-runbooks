local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local serviceDashboard = import 'service_dashboard.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';

serviceDashboard.overview('mailroom', 'sv')
.addPanel(
  row.new(title='Mailroom Metrics'),
  gridPos={ x: 0, y: 1000, w: 24, h: 1 }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Unread Emails',
      description='Number of unread messages',
      query='max(imap_nb_unread_messages_in_mailbox{environment=~"$environment"})',
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
