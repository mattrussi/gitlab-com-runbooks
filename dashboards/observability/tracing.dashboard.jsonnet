local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

local k8sPodsCommon = import 'gitlab-dashboards/kubernetes_pods_common.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';

local env_cluster_ns = 'env=~"$environment", cluster="$cluster", namespace="$namespace"';

basic.dashboard(
  'Tracing',
  tags=[
    'gitlab-observability',
  ],
)
.addTemplate(templates.Node)
.addTemplate(
  template.custom(
    name='environment',
    label='Environment',
    query='gstg,gprd',
    current='gprd',
  )
)
.addTemplate(
  template.new(
    'cluster',
    '$PROMETHEUS_DS',
    'label_values(kube_pod_container_info{env="$environment", cluster=~"opstrace-.*"}, cluster)',
    label='Cluster',
    refresh='load',
    sort=1,
  )
)
.addTemplate(
  template.new(
    'namespace',
    '$PROMETHEUS_DS',
    'label_values(kube_namespace_labels{namespace=~"tenant-.*"}, namespace)',
    label='Namespace',
    refresh='time',
    multi=false,
    includeAll=false,
  )
)
.addPanel(
  row.new(title='Deployment Status'),
  gridPos={ x: 0, y: 0, w: 24, h: 1 },
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Active Version - otel-collector',
      query=|||
        count(
          kube_pod_container_info{%(env_cluster_ns)s, container="otel-collector"}
        ) by (image)
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ image }}',
    ),
    basic.timeseries(
      title='Up - otel-collector/metrics',
      query=|||
        up{%(env_cluster_ns)s, container="otel-collector", job="otel-collector", endpoint="metrics"}
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ namespace }}',
    ),
    basic.timeseries(
      title='Process uptime - otel-collector',
      query=|||
        otelcol_process_uptime{%(env_cluster_ns)s, container="otel-collector"}
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ namespace }}',
    )
  ], cols=3, rowHeight=8, startRow=1)
)
.addPanel(
  row.new(title='HTTP Receiver'),
  gridPos={ x: 0, y: 100, w: 24, h: 1}
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Accepted Spans',
      query=|||
        sum (
          rate(otelcol_receiver_accepted_spans{%(env_cluster_ns)s, container="otel-collector"}[1m])
        ) by (namespace)
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ namespace }}',
    ),
    basic.timeseries(
      title='Refused Spans',
      query=|||
        sum (
          rate(otelcol_receiver_refused_spans{%(env_cluster_ns)s, container="otel-collector"}[1m])
        ) by (namespace)
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ namespace }}',
    ),
  ], cols=2, rowHeight=8, startRow=101)
)
.addPanel(
  row.new(title='ClickHouse Exporter'),
  gridPos={ x: 0, y: 200, w: 24, h: 1 },
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Spans Received',
      query=|||
        sum (
          rate(custom_spans_received{%(env_cluster_ns)s, container="otel-collector"}[1m])
        ) by (group)
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ group }}',
    ),
    basic.timeseries(
      title='Spans Ingested',
      query=|||
        sum (
          rate(custom_spans_ingested{%(env_cluster_ns)s, container="otel-collector"}[1m])
        ) by (group)
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ group }}',
    ),
    basic.timeseries(
      title='Traces Total Bytes',
      query=|||
        sum (
          rate(custom_traces_size_bytes{%(env_cluster_ns)s, container="otel-collector"}[1m])
        ) by (group)
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ group }}',
    )
  ], cols=3, rowHeight=8, startRow=201)
)
.addPanel(
  row.new(title='Resource Utilisation'),
  gridPos={ x: 0, y: 300, w: 24, h: 1 },
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='CPU - otel-collector (millicores)',
      query=|||
        sum(
          rate(container_cpu_usage_seconds_total{%(env_cluster_ns)s, container="otel-collector"}[2m])
        ) by (namespace) * 1000
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ namespace }}',
    ),
    basic.timeseries(
      title='Memory - otel-collector (GBs)',
      query=|||
        sum(
          rate(container_memory_working_set_bytes{%(env_cluster_ns)s, container="otel-collector"}[2m])
        ) by (namespace) / (1024*1024*1024)
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ namespace }}',
    )
  ], cols=2, rowHeight=8, startRow=301)
)
.addPanel(
  row.new(title='Pipeline Scalability'),
  gridPos={ x: 0, y: 400, w: 24, h: 1 },
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Memory-Limiter Refused Spans',
      query=|||
        sum (
          rate(otelcol_processor_refused_spans{%(env_cluster_ns)s, container="otel-collector"}[1m])
        ) by (namespace)
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ namespace }}',
    ),
    basic.timeseries(
      title='Exporter Queue Capacity',
      query=|||
        otelcol_exporter_queue_capacity{%(env_cluster_ns)s, container="otel-collector"}
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ namespace }}',
    ),
    basic.timeseries(
      title='Exporter Queue Size',
      query=|||
        otelcol_exporter_queue_size{%(env_cluster_ns)s, container="otel-collector"}
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ namespace }}',
    ),
    basic.timeseries(
      title='Exporter Enqueue Failed Spans',
      query=|||
        sum (
          rate(otelcol_exporter_enqueue_failed_spans{%(env_cluster_ns)s, container="otel-collector"}[1m])
        ) by (namespace)
      ||| % { env_cluster_ns: env_cluster_ns },
      legendFormat='{{ namespace }}',
    ),
  ], cols=4, rowHeight=8, startRow=401)
)
