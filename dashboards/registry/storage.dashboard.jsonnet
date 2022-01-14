local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

basic.dashboard(
  'Storage Detail',
  tags=['container registry', 'docker', 'registry', 'type:registry'],
)
.addTemplate(templates.gkeCluster)
.addTemplate(templates.stage)
.addTemplate(templates.namespaceGitlab)
.addTemplate(
  template.custom(
    'Deployment',
    'gitlab-registry,',
    'gitlab-registry',
    hide='variable',
  )
)
.addTemplate(template.new(
  'cluster',
  '$PROMETHEUS_DS',
  'label_values(registry_storage_action_seconds_count{environment="$environment"}, cluster)',
  current=null,
  refresh='load',
  sort=true,
  multi=true,
  includeAll=true,
  allValues='.*',
))
.addPanel(
  row.new(title='GCS Bucket'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Total Size',
      description='Total size of objects per bucket. Values are measured once per day.',
      query='stackdriver_gcs_bucket_storage_googleapis_com_storage_total_bytes{bucket_name=~"gitlab-.*-registry", environment="$environment"}',
      legendFormat='{{ bucket_name }}',
      format='bytes'
    ),
    basic.timeseries(
      title='Object Count',
      description='Total number of objects per bucket, grouped by storage class. Values are measured once per day.',
      query='sum by (storage_class) (stackdriver_gcs_bucket_storage_googleapis_com_storage_object_count{bucket_name=~"gitlab-.*-registry", environment="$environment"})',
      legendFormat='{{ storage_class }}'
    ),
    basic.timeseries(
      title='Daily Throughput',
      description='Total daily storage in byte*seconds used by the bucket, grouped by storage class.',
      query='sum by (storage_class) (stackdriver_gcs_bucket_storage_googleapis_com_storage_total_byte_seconds{bucket_name=~"gitlab-.*-registry", environment="$environment"})',
      format='Bps',
      yAxisLabel='Bytes/s',
      legendFormat='{{ storage_class }}'
    ),
  ], cols=3, rowHeight=10, startRow=1)
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='RPS (Overall)',
      query='sum(rate(registry_storage_action_seconds_count{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))'
    ),
    basic.timeseries(
      title='RPS (Per Action)',
      query=|||
        sum by (action) (
          rate(registry_storage_action_seconds_count{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
        )
      |||,
      legendFormat='{{ action }}'
    ),
    basic.timeseries(
      title='Estimated p95 Latency (Overall)',
      query=|||
        histogram_quantile(
          0.950000,
          sum by (le) (
            rate(registry_storage_action_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        )
      |||,
      format='s'
    ),
    basic.timeseries(
      title='Estimated p95 Latency (Per Action)',
      query=|||
        histogram_quantile(
          0.950000,
          sum by (action,le) (
            rate(registry_storage_action_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        )
      |||,
      format='s',
      legendFormat='{{ action }}'
    ),
  ], cols=4, rowHeight=10, startRow=1001)
)
.addPanel(
  row.new(title='Cloud CDN Requests'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='HTTP Requests CACHE HIT',
      description='HTTP Requests',
      query='sum(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count{cache_result="HIT", environment="$environment", forwarding_rule_name=~".*registry-cdn.*"}) by (response_code) / 60',
      legendFormat='{{ response_code }}',
      format='ops',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='HTTP Requests CACHE HIT (bytes)',
      description='HTTP Requests',
      query='sum(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_request_bytes_count{cache_result="HIT", environment="$environment", forwarding_rule_name=~".*registry-cdn.*"}) by (response_code)',
      legendFormat='{{ response_code }}',
      format='bytes',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='HTTP Requests CACHE MISS',
      description='HTTP Requests',
      query='sum(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count{cache_result="MISS", environment="$environment", forwarding_rule_name=~".*registry-cdn.*"}) by (response_code) / 60',
      legendFormat='{{ response_code }}',
      format='ops',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='HTTP Requests CACHE MISS (bytes)',
      description='HTTP Requests',
      query='sum(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_request_bytes_count{cache_result="MISS", environment="$environment", forwarding_rule_name=~".*registry-cdn.*"}) by (response_code)',
      legendFormat='{{ response_code }}',
      format='bytes',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
  ], cols=2, rowHeight=10, startRow=2001)
)

.addPanel(
  row.new(title='Cloud CDN Latencies'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='60th Percentile Latency CACHE HIT',
      description='60th Percentile Latency CACHE MISS',
      query='histogram_quantile(0.6,rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_latencies_bucket{cache_result="HIT", environment="$environment", forwarding_rule_name=~".*registry-cdn.*"}[10m]))',
      legendFormat='{{ response_code }}',
      format='ms',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='90th Percentile Latency CACHE HIT',
      description='90th Percentile Latency CACHE MISS',
      query='histogram_quantile(0.9,rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_latencies_bucket{cache_result="HIT", environment="$environment", forwarding_rule_name=~".*registry-cdn.*"}[10m]))',
      legendFormat='{{ response_code }}',
      format='ms',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='60th Percentile Latency CACHE MISS',
      description='60th Percentile Latency CACHE MISS',
      query='histogram_quantile(0.6,rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_latencies_bucket{cache_result="MISS", environment="$environment", forwarding_rule_name=~".*registry-cdn.*"}[10m]))',
      legendFormat='{{ response_code }}',
      format='ms',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='90th Percentile Latency CACHE MISS',
      description='90th Percentile Latency CACHE MISS',
      query='histogram_quantile(0.9,rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_latencies_bucket{cache_result="MISS", environment="$environment", forwarding_rule_name=~".*registry-cdn.*"}[10m]))',
      legendFormat='{{ response_code }}',
      format='ms',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
  ], cols=2, rowHeight=10, startRow=3001)
)
