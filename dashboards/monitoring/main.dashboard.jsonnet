local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local thresholds = import 'gitlab-dashboards/thresholds.libsonnet';

serviceDashboard.overview('monitoring')
.addPanel(
  row.new(title='Grafana CloudSQL', collapse=true)
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
    ], cols=3, rowHeight=10, startRow=2001)
  ),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  },
)
.addPanel(
  row.new(title='Grafana Latencies'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(layout.grid([
  basic.latencyTimeseries(
    title='Grafana API Dataproxy (logn scale)',
    legend_show=false,
    format='ms',
    query=|||
      grafana_api_dataproxy_request_all_milliseconds{environment="ops", quantile="0.5"}
    |||,
    legendFormat='p50 {{ pod }}',
    intervalFactor=2,
    logBase=10,
    min=10
  )
  .addTarget(
    promQuery.target(
      |||
        grafana_api_dataproxy_request_all_milliseconds{environment="ops", quantile="0.9"}
      |||,
      legendFormat='p90 {{ pod }}',
      intervalFactor=2,
    )
  )
  .addTarget(
    promQuery.target(
      |||
        grafana_api_dataproxy_request_all_milliseconds{environment="ops", quantile="0.99"}
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
], cols=1, rowHeight=10, startRow=1001))
.overviewTrailer()
