local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local graphPanel = grafana.graphPanel;
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local thresholds = import 'gitlab-dashboards/thresholds.libsonnet';

serviceDashboard.overview('monitoring')
.addPanel(
  row.new(title='Grafana CloudSQL Details', collapse=true)
  .addPanels(
    layout.grid([
      basic.timeseries(
        title='CPU Utilization',
        description=|||
          CPU utilization.

          See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
          more details.
        |||,
        query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_cpu_utilization{database_id=~".+:grafana-(pre|internal)-.+", environment="$environment"}',
        legendFormat='{{ database_id }}',
        format='percent'
      ),

      basic.timeseries(
        title='Memory Utilization',
        description=|||
          Memory utilization.

          See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
          more details.
        |||,
        query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_memory_utilization{database_id=~".+:grafana-(pre|internal)-.+", environment="$environment"}',
        legendFormat='{{ database_id }}',
        format='percent'
      ),

      basic.timeseries(
        title='Disk Utilization',
        description=|||
          Data utilization in bytes.

          See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
          more details.
        |||,
        query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_disk_bytes_used{database_id=~".+:grafana-(pre|internal)-.+", environment="$environment"}',
        legendFormat='{{ database_id }}',
        format='bytes'
      ),

      basic.timeseries(
        title='Transactions',
        description=|||
          Delta count of number of transactions. Sampled every 60 seconds.

          See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
          more details.
        |||,
        query=|||
          sum by (database_id) (
            avg_over_time(stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_transaction_count{database_id=~".+:grafana-(pre|internal)-.+", environment="$environment"}[$__interval])
          )
        |||,
        legendFormat='{{ database_id }}',
      ),
    ], cols=4, rowHeight=10, startRow=1000)
  ),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  },
)
.addPanel(
  row.new(title='Grafana Latencies', collapse=true)
  .addPanels(
    layout.grid([
      basic.latencyTimeseries(
        title='Grafana API Dataproxy Request Duration (logn scale)',
        legend_show=false,
        format='ms',
        query=|||
          grafana_api_dataproxy_request_all_milliseconds{environment="$environment", quantile="0.5"}
        |||,
        legendFormat='p50 {{ pod }}',
        intervalFactor=2,
        logBase=10,
        min=10
      )
      .addTarget(
        promQuery.target(
          |||
            grafana_api_dataproxy_request_all_milliseconds{environment="$environment", quantile="0.9"}
          |||,
          legendFormat='p90 {{ pod }}',
          intervalFactor=2,
        )
      )
      .addTarget(
        promQuery.target(
          |||
            grafana_api_dataproxy_request_all_milliseconds{environment="$environment", quantile="0.99"}
          |||,
          legendFormat='p99 {{ pod }}',
          intervalFactor=2,
        )
      ) + {
        thresholds: [
          thresholds.warningLevel('gt', 10000),
          thresholds.errorLevel('gt', 30000),
        ],
      },

      basic.timeseries(
        title='Grafana Datasource RPS',
        legend_show=false,
        query=|||
          sum(rate(grafana_datasource_request_total{environment="$environment"}[$__interval])) by (datasource)
        |||,
        legendFormat='{{ datasource }}',
        intervalFactor=2,
      ),

      basic.latencyTimeseries(
        title='Grafana Datasource Request Duration (logn scale)',
        legend_show=false,
        format='s',
        query=|||
          avg(grafana_datasource_request_duration_seconds{environment="$environment"} >= 0) by (datasource)
        |||,
        legendFormat='{{ datasource }}',
        intervalFactor=2,
        logBase=10,
      ) + {
        thresholds: [
          thresholds.warningLevel('gt', 10),
          thresholds.errorLevel('gt', 30),
        ],
      },
    ], cols=3, rowHeight=10, startRow=1000),
  ),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  },
)
.addPanel(
  row.new(title='Grafana Trickster Details', collapse=true)
  .addPanels(
    layout.grid([
      basic.timeseries(
        title='Trickster Frontend RPS By Path',
        legend_show=false,
        query=|||
          sum(rate(trickster_frontend_requests_total{environment="$environment"}[$__interval])) by (path)
        |||,
        legendFormat='{{ path }}',
      ),

      basic.timeseries(
        title='Trickster Proxy RPS By Origin',
        legend_show=false,
        query=|||
          sum(rate(trickster_proxy_requests_total{environment="$environment"}[$__interval])) by (origin_name)
        |||,
        legendFormat='{{ origin_name }}',
      ),

      basic.latencyTimeseries(
        title='Trickster Proxy Request Duration (logn scale)',
        legend_show=false,
        format='s',
        query=|||
          histogram_quantile(0.5, sum(rate(trickster_proxy_request_duration_seconds_bucket{env="$environment"}[$__interval])) by (le, origin_name))
        |||,
        legendFormat='p50 {{ origin_name }}',
        intervalFactor=2,
        logBase=10,
        min=0.01,
      )
      .addTarget(
        promQuery.target(
          |||
            histogram_quantile(0.9, sum(rate(trickster_proxy_request_duration_seconds_bucket{env="$environment"}[$__interval])) by (le, origin_name))
          |||,
          legendFormat='p90 {{ origin_name }}',
          intervalFactor=2,
        )
      )
      .addTarget(
        promQuery.target(
          |||
            histogram_quantile(0.99, sum(rate(trickster_proxy_request_duration_seconds_bucket{env="$environment"}[$__interval])) by (le, origin_name))
          |||,
          legendFormat='p99 {{ origin_name }}',
          intervalFactor=2,
        )
      ) + {
        thresholds: [
          thresholds.warningLevel('gt', 10),
          thresholds.errorLevel('gt', 30),
        ],
      },

      graphPanel.new(
        'Trickster Cache Hit/Miss Ratio',
        bars=true,
        lines=false,
        stack=true,
        percentage=true,
        legend_show=false,
        decimals=2,
        format='short',
        max=100,
        min=0,
        datasource='$PROMETHEUS_DS',
      )
      .addTarget(
        promQuery.target(
          |||
            sum(increase(trickster_proxy_points_total{environment="$environment"}[$__interval])) by (cache_status)
          |||,
          legendFormat='{{ cache_status }}',
          interval='1m',
          intervalFactor=3,
        )
      ),

      graphPanel.new(
        'Trickster Cache Events',
        lines=false,
        points=true,
        pointradius=5,
        legend_show=false,
        decimals=0,
        format='short',
        datasource='$PROMETHEUS_DS',
      )
      .addTarget(
        promQuery.target(
          |||
            sum(increase(trickster_cache_events_total{environment="$environment"}[$__interval])) by (cache_name, event) > 0
          |||,
          legendFormat='{{ cache_name }} - {{ event }}',
          interval='1m',
          intervalFactor=3,
        )
      ),
    ], cols=3, rowHeight=10, startRow=1000),
  ),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  },
)
.overviewTrailer()
