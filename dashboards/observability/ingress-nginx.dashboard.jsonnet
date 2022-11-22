local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local k8sPodsCommon = import 'gitlab-dashboards/kubernetes_pods_common.libsonnet';
local platformLinks = import 'gitlab-dashboards/platform_links.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

basic.dashboard(
  'Ingress-nginx',
  tags=[
    'k8s',
    'gos',
    'gitlab-observability',
  ],
)
.addTemplate(templates.Node)
.addTemplate(template.new(
  'environment',
  '$PROMETHEUS_DS',
  'label_values(kube_pod_container_info{cluster=~"opstrace-.*"}, env)',
  label='Environment',
  refresh='load',
  sort=1,
))
.addTemplate(template.new(
  'cluster',
  '$PROMETHEUS_DS',
  'label_values(kube_pod_container_info{cluster=~"opstrace-.*"}, cluster)',
  label='Cluster',
  refresh='load',
  sort=1,
))
.addTemplate(template.new(
  'nginxPods',
  '$PROMETHEUS_DS',
  'label_values(kube_pod_container_info{cluster=~"opstrace-.*", container="nginx-ingress"}, pod)',
  label='Nginx pods',
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true,
))
.addTemplate(
  template.custom(
    name='Deployment',
    query='nginx-ingress,',
    current='nginx-ingress',
    hide='variable',
  )
)
.addTemplate(
  template.custom(
    name='namespace',
    query='default,',
    current='default',
    hide='variable',
  )
)
.addPanel(
  row.new(title='Ingress-nginx version'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sPodsCommon.version(startRow=1))
.addPanel(
  row.new(title='Deployment Info'),
  gridPos={
    x: 0,
    y: 100,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sPodsCommon.deployment(startRow=101))
.addPanels(k8sPodsCommon.status(startRow=102))
.addPanel(
  row.new(title='CPU'),
  gridPos={
    x: 0,
    y: 200,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sPodsCommon.cpu(startRow=201))
.addPanel(
  row.new(title='Memory'),
  gridPos={
    x: 0,
    y: 300,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sPodsCommon.memory(startRow=301, container='nginx-ingress'))
.addPanel(
  row.new(title='Network'),
  gridPos={
    x: 0,
    y: 400,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sPodsCommon.network(startRow=401))
.addPanel(
  row.new(title='Request Handling Performance'),
  gridPos={
    x: 0,
    y: 500,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Requests per second by HTTP status',
      query='sum(rate(nginx_ingress_controller_request_duration_seconds_count{env="$environment", cluster=~"$cluster", pod=~"$nginxPods"}[$__rate_interval])) by (status) > 0 ',
      legendFormat='HTTP {{status}}',
      yAxisLabel='conn/sec',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
    basic.multiQuantileTimeseries(
      title='Requests duration by HTTP status',
      selector='env="$environment", cluster=~"$cluster", pod=~"$nginxPods"',
      legendFormat='HTTP {{status}}',
      bucketMetric='nginx_ingress_controller_request_duration_seconds_bucket',
      aggregators='status',
      legend_rightSide=true,
    ),
    basic.timeseries(
      title='Requests per second by ingress',
      query='sum(rate(nginx_ingress_controller_request_duration_seconds_count{env="$environment", cluster=~"$cluster", pod=~"$nginxPods"}[$__rate_interval])) by (host, path) > 0 ',
      legendFormat='{{host}}{{path}}',
      yAxisLabel='req/sec',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
    basic.multiQuantileTimeseries(
      title='Requests duration by ingress',
      selector='env="$environment", cluster=~"$cluster", pod=~"$nginxPods"',
      legendFormat='{{host}}{{path}}',
      bucketMetric='nginx_ingress_controller_request_duration_seconds_bucket',
      aggregators='host,path',
      legend_rightSide=true,
    ),
    basic.timeseries(
      title='Connections per second',
      query='sum(rate(nginx_ingress_controller_nginx_process_connections_total{env="$environment", cluster=~"$cluster", pod=~"$nginxPods"}[$__rate_interval])) by (state)',
      legendFormat='{{state}}',
      yAxisLabel='conn/sec',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
    basic.timeseries(
      title='Response Error Rate by Method and Path',
      query='sum by (method, host, path) (rate(nginx_ingress_controller_request_duration_seconds_count{env="$environment", cluster=~"$cluster", pod=~"$nginxPods", status =~ "[4-5].*"}[$__rate_interval]))',
      legendFormat='{{ method }} {{ host }}{{ path }}',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
  ], cols=2, rowHeight=10, startRow=601)
)
