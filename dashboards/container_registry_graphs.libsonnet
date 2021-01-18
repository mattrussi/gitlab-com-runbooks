local basic = import 'grafana/basic.libsonnet';
local colorScheme = import 'grafana/color_scheme.libsonnet';
local layout = import 'grafana/layout.libsonnet';

{
  data(startRow)::
    layout.grid([
      basic.timeseries(
        title='HTTP Requests',
        query='sum(irate(registry_http_requests_total{cluster="$cluster", namespace="$namespace"}[1m])) by (method, route, code)',
        legendFormat='{{ method }} {{ route }}: {{ code }}',
      ),
      basic.timeseries(
        title='In-Flight HTTP Requests',
        query='sum(irate(registry_http_in_flight_requests{cluster="$cluster", namespace="$namespace"}[1m])) by (method, route, code)',
        legendFormat='{{ method }} {{ route }}',
      ),
      basic.timeseries(
        title='Registry Action Latency',
        query='avg(increase(registry_storage_action_seconds_sum{job=~".*registry.*", cluster="$cluster", namespace="$namespace"}[$__interval])) by (action)',
        legendFormat='{{ action }}',
      ),
      basic.timeseries(
        title='Cache Requests Rate',
        query='sum(irate(registry_storage_cache_total{cluster="$cluster", namespace="$namespace"}[1m])) by (type)',
        legend_show=false,
      ),
      basic.singlestat(
        title='Cache Hit %',
        query='sum(rate(registry_storage_cache_total{cluster="$cluster", environment="$environment", namespace="$namespace",exported_type="Hit"}[$__interval])) / sum(rate(registry_storage_cache_total{environment="$environment",exported_type="Request"}[$__interval]))',
        colors=[
          colorScheme.criticalColor,
          colorScheme.errorColor,
          colorScheme.normalRangeColor,
        ],
        gaugeMaxValue=1,
        gaugeShow=true,
        thresholds='0.5,0.75',
      ),
    ], cols=2, rowHeight=10, startRow=startRow),

  latencies(startRow):: layout.grid([
    basic.heatmap(
      title='manifest',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/{name}/manifests/{reference}",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob_upload_chunk',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/{name}/blobs/uploads/{uuid}", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/{name}/blobs/{digest}",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='base',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='tags',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/{name}/tags/list", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob_upload',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/{name}/blobs/uploads/", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
  ], cols=3, rowHeight=10, startRow=startRow),

  version(startRow)::
    layout.grid([
      basic.timeseries(
        title='Version',
        query='count(gitlab_build_info{app="registry", cluster="$cluster", namespace="$namespace"}) by (version)',
        legendFormat='{{ version }}',
      ),
    ], cols=2, rowHeight=5, startRow=startRow),
}
