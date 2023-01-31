local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local row = grafana.row;

basic.dashboard(
  'Kube Sentry main',
  tags=['sentry'],
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)

.addPanel(
  row.new(title='Sentry Application'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Events processed per minute',
      query='rate(sentry_ingest_consumer_process_event_count[1m])',
      legendFormat='__auto',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Job duration',
      query='sentry_jobs_duration',
      legendFormat='{{ pod }}',
      legend_show=true,
      format='ms',
      linewidth=2
    ),
    basic.timeseries(
      title='Time to process events',
      query='sentry_ingest_consumer_process_event',
      legendFormat='{{ quantile }}',
      legend_show=true,
      format='ms',
      linewidth=2
    ),
  ], cols=2, rowHeight=10, startRow=0)
)
.addPanel(
  row.new(title='Nginx'),
  gridPos={
    x: 0,
    y: 100,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Active connections',
      query='sum by(pod) (nginx_ingress_controller_nginx_process_connections{namespace="sentry"})',
      legendFormat='__auto',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Requests in 5 minutes',
      query='sum by(exported_service) (rate(nginx_ingress_controller_requests{namespace="sentry", exported_service=~"sentry-relay|sentry-web"}[5m]))',
      legendFormat='{{ exported_service }}',
      legend_show=true,
      linewidth=2
    ),
  ], cols=2, rowHeight=10, startRow=101)
)
.addPanel(
  row.new(title='Clickhouse'),
  gridPos={
    x: 0,
    y: 200,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Active connections',
      query='sum(ClickHouseMetrics_TCPConnection)',
      legendFormat='__auto',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Replica delay',
      query='ClickHouseAsyncMetrics_ReplicasMaxAbsoluteDelay',
      legendFormat='{{ pod }}',
      format='s',
      legend_show=true,
      linewidth=2
    ),
    basic.multiTimeseries(
      title='Active vs Waiting Readers/Writers',
      queries=[
        {
          query: 'sum(ClickHouseMetrics_RWLockActiveReaders)',
          legendFormat: 'Active Readers',
        },
        {
          query: 'sum(ClickHouseMetrics_RWLockActiveWriters)',
          legendFormat: 'Active Writers',
        },
        {
          query: 'sum(ClickHouseMetrics_RWLockWaitingReaders)',
          legendFormat: 'Waiting Readers',
        },
        {
          query: 'sum(ClickHouseMetrics_RWLockWaitingWriters)',
          legendFormat: 'Waiting Writers',
        },
      ],
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Zookeeper requests',
      query='sum(ClickHouseMetrics_ZooKeeperRequest)',
      legendFormat='__auto',
      legend_show=true,
      linewidth=2
    ),
  ], cols=2, rowHeight=10, startRow=201)
)
