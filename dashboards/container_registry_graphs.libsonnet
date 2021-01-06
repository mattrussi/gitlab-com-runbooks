local basic = import 'grafana/basic.libsonnet';
local colorScheme = import 'grafana/color_scheme.libsonnet';
local layout = import 'grafana/layout.libsonnet';

{
  data(startRow)::
    layout.grid([
      basic.timeseries(
        title='HTTP Requests',
        query='sum(irate(registry_http_requests_total{cluster="$cluster", namespace="$namespace"}[1m])) by (method, handler, code)',
        legendFormat='{{ method }} {{ handler }}: {{ code }}',
      ),
      basic.timeseries(
        title='In-Flight HTTP Requests',
        query='sum(irate(registry_http_in_flight_requests{cluster="$cluster", namespace="$namespace"}[1m])) by (method, handler, code)',
        legendFormat='{{ method }} {{ handler }}',
      ),
      // TODO: remove the two timeseries above and rename the two below (removing the `  (by route)` suffix) once registry v2.13.0-gitlab is deployed (see https://gitlab.com/gitlab-com/runbooks/-/merge_requests/3094)
      basic.timeseries(
        title='HTTP Requests (by route)',
        query='sum(irate(registry_http_requests_total{cluster="$cluster", namespace="$namespace"}[1m])) by (method, route, code)',
        legendFormat='{{ method }} {{ route }}: {{ code }}',
      ),
      basic.timeseries(
        title='In-Flight HTTP Requests (by route)',
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
      query='rate(registry_http_request_duration_seconds_bucket{handler="manifest",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob_upload_chunk',
      query='rate(registry_http_request_duration_seconds_bucket{handler="blob_upload_chunk", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob',
      query='rate(registry_http_request_duration_seconds_bucket{handler="blob",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='base',
      query='rate(registry_http_request_duration_seconds_bucket{handler="base",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='tags',
      query='rate(registry_http_request_duration_seconds_bucket{handler="tags", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob_upload',
      query='rate(registry_http_request_duration_seconds_bucket{handler="blob_upload", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    // TODO: remove all heatmaps above and rename all below (removing the `  (by route)` suffix) once registry v2.13.0-gitlab is deployed (see https://gitlab.com/gitlab-com/runbooks/-/merge_requests/3094)
    basic.heatmap(
      title='manifest (by route)',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/{name}/manifests/{reference}",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob_upload_chunk (by route)',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/{name}/blobs/uploads/{uuid}", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob (by route)',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/{name}/blobs/{digest}",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='base (by route)',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='tags (by route)',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/{name}/tags/list", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob_upload (by route)',
      query='rate(registry_http_request_duration_seconds_bucket{route="/v2/{name}/blobs/uploads/", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
  ], cols=3, rowHeight=10, startRow=startRow),
}
