local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local row = grafana.row;

local clusterSelector = {
  cluster: 'ops-gitlab-gke',
  env: 'ops',
  namespace: 'sentry',
};
local clusterSelectorSerialized = selectors.serializeHash(clusterSelector);

local clickhouseSelector = {
  chi: 'sentry',
};
local clickhouseSelectorSerialized = selectors.serializeHash(clickhouseSelector);

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
      query='rate(sentry_ingest_consumer_process_event_count{%(selector)s}[1m])' % { selector: clusterSelectorSerialized },
      legendFormat='__auto',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Job duration',
      query='sentry_jobs_duration{%(selector)s}' % { selector: clusterSelectorSerialized },
      legendFormat='{{ quantile }}',
      legend_show=true,
      format='ms',
      linewidth=2
    ),
    basic.timeseries(
      title='Time to process events',
      query='sentry_ingest_consumer_process_event{%(selector)s}' % { selector: clusterSelectorSerialized },
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
      query='sum by(pod) (nginx_ingress_controller_nginx_process_connections{%(selector)s})' % { selector: clusterSelectorSerialized },
      legendFormat='__auto',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Requests in 5 minutes',
      query='sum by(exported_service) (rate(nginx_ingress_controller_requests{%(selector)s, exported_service=~"sentry-relay|sentry-web"}[5m]))' % { selector: clusterSelectorSerialized },
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
      query='sum by(hostname)(chi_clickhouse_metric_TCPConnection{%(selector)s})' % { selector: clickhouseSelectorSerialized },
      legendFormat='__auto',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Replica delay',
      query='chi_clickhouse_metric_ReplicasMaxAbsoluteDelay{%(selector)s}' % { selector: clickhouseSelectorSerialized },
      legendFormat='{{ hostname }}',
      format='s',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Zookeeper requests',
      query='sum by(hostname)(chi_clickhouse_metric_ZooKeeperRequest{%(selector)s})' % { selector: clickhouseSelectorSerialized },
      legendFormat='__auto',
      legend_show=true,
      linewidth=2
    ),
  ], cols=2, rowHeight=10, startRow=201)
)
.addPanel(
  row.new(title='Kafka'),
  gridPos={
    x: 0,
    y: 300,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Consumer group lag by topic',
      query='kafka_consumergroup_lag{%(selector)s}' % { selector: clusterSelectorSerialized },
      legendFormat='{{ topic }} in group {{ consumergroup }}',
      legend_show=true,
      linewidth=2
    ),
  ], cols=2, rowHeight=10, startRow=301)
)
