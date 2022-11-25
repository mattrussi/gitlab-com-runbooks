local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local k8sPodsCommon = import 'gitlab-dashboards/kubernetes_pods_common.libsonnet';
local platformLinks = import 'gitlab-dashboards/platform_links.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

basic.dashboard(
  'Errortracking API',
  tags=[
    'k8s',
    'gos',
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
.addTemplate(template.new(
  'cluster',
  '$PROMETHEUS_DS',
  'label_values(kube_pod_container_info{env="$environment", cluster=~"opstrace-.*"}, cluster)',
  label='Cluster',
  refresh='load',
  sort=1,
))
.addTemplate(template.new(
  'namespace',
  '$PROMETHEUS_DS',
  'label_values(kube_deployment_status_replicas{env="$environment", cluster=~"opstrace-.*", deployment=~"^errortracking-.*$"}, namespace)',
  label='Errortracking-api namespace',
  refresh='time',
  multi=false,
  includeAll=false,
))
.addTemplate(template.new(
  'errortrackingPods',
  '$PROMETHEUS_DS',
  'label_values(kube_pod_container_info{env="$environment", cluster=~"opstrace-.*", container="errortracking-api", namespace="$namespace"}, pod)',
  label='Errortracking-api pods',
  refresh='time',
  sort=1,
  multi=true,
  includeAll=true,
))
.addTemplate(
  template.custom(
    name='Deployment',
    query='errortracking,',
    current='errortracking',
    hide='variable',
  )
)
.addPanel(
  row.new(title='Errortracking API version'),
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
.addPanels(k8sPodsCommon.memory(startRow=301, container='errortracking-api'))
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
      query='sum(rate(http_requests_duration_seconds_count{env="$environment", cluster=~"$cluster", pod=~"$errortrackingPods"}[$__rate_interval])) by (code) > 0 ',
      legendFormat='HTTP {{code}}',
      yAxisLabel='req/sec',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
    basic.multiQuantileTimeseries(
      title='Requests duration by HTTP status',
      selector='env="$environment", cluster=~"$cluster", pod=~"$errortrackingPods"',
      legendFormat='HTTP {{code}}',
      bucketMetric='http_requests_duration_seconds_bucket',
      aggregators='code',
      legend_rightSide=true,
    ),
    basic.timeseries(
      title='Requests per second by path',
      query='sum(rate(http_requests_duration_seconds_count{env="$environment", cluster=~"$cluster", pod=~"$errortrackingPods"}[$__rate_interval])) by (path) > 0 ',
      legendFormat='{{path}}',
      yAxisLabel='req/sec',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
    basic.multiQuantileTimeseries(
      title='Requests duration by path',
      selector='env="$environment", cluster=~"$cluster", pod=~"$errortrackingPods"',
      legendFormat='{{path}}',
      bucketMetric='http_requests_duration_seconds_bucket',
      aggregators='path',
      legend_rightSide=true,
    ),
    basic.timeseries(
      title='Response Error Rate by Method and Path',
      query='sum by (method, path) (rate(http_requests_duration_seconds_count{env="$environment", cluster=~"$cluster", pod=~"$errortrackingPods", code =~ "[4-5].*"}[$__rate_interval]))',
      legendFormat='{{ method }} {{ path }}',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
  ], cols=2, rowHeight=10, startRow=601)
)
.addPanel(
  row.new(title='Project data'),
  gridPos={
    x: 0,
    y: 700,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Envelope requests by project ID',
      query='sum(rate(project_envelope_total{env="$environment", cluster=~"$cluster", pod=~"$errortrackingPods"}[$__rate_interval])) by (projectID)',
      legendFormat='{{projectID}}',
      yAxisLabel='req/sec',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
    basic.timeseries(
      title='Get error requests by project ID',
      query='sum(rate(project_get_error_total{env="$environment", cluster=~"$cluster", pod=~"$errortrackingPods"}[$__rate_interval])) by (projectID)',
      legendFormat='{{projectID}}',
      yAxisLabel='req/sec',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
    basic.timeseries(
      title='List errors requests by project ID',
      query='sum(rate(project_list_errors_total{env="$environment", cluster=~"$cluster", pod=~"$errortrackingPods"}[$__rate_interval])) by (projectID)',
      legendFormat='{{projectID}}',
      yAxisLabel='req/sec',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
    basic.timeseries(
      title='List events requests by project ID',
      query='sum(rate(project_list_events_total{env="$environment", cluster=~"$cluster", pod=~"$errortrackingPods"}[$__rate_interval])) by (projectID)',
      legendFormat='{{projectID}}',
      yAxisLabel='req/sec',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
    basic.timeseries(
      title='Store requests by project ID',
      query='sum(rate(project_store_total{env="$environment", cluster=~"$cluster", pod=~"$errortrackingPods"}[$__rate_interval])) by (projectID)',
      legendFormat='{{projectID}}',
      yAxisLabel='req/sec',
      fill=5,
      stack=true,
      legend_rightSide=true,
    ),
  ], cols=2, rowHeight=10, startRow=701)
)
