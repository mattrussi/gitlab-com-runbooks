local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';

local row = grafana.row;
local template = grafana.template;

local databaseId = 'gitlab-ops:packagecloud-f05c90f5';
local useTimeSeriesPlugin = true;

serviceDashboard.overview(
  'packagecloud',
  omitEnvironmentDropdown=true,
)
.addTemplate(
  template.custom(
    'environment',
    'ops,pre,',
    'ops',
  ),
)
.addPanel(
  row.new(title='💾 CloudSQL', collapse=true)
  .addPanels(
    layout.grid(
      if useTimeSeriesPlugin then
        [
          panel.timeSeries(
            title='CPU Utilization',
            description=|||
              CPU utilization.

              See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
              more details.
            |||,
            query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_cpu_utilization{database_id="%s", environment="ops"} * 100' % databaseId,
            legendFormat='{{ database_id }}',
            format='percent'
          ),
          panel.timeSeries(
            title='Memory Utilization',
            description=|||
              Memory utilization.

              See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
              more details.
            |||,
            query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_memory_utilization{database_id="%s", environment="ops"} * 100' % databaseId,
            legendFormat='{{ database_id }}',
            format='percent'
          ),
          panel.timeSeries(
            title='Disk Utilization',
            description=|||
              Data utilization in bytes.

              See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
              more details.
            |||,
            query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_disk_bytes_used{database_id="%s", environment="ops"}' % databaseId,
            legendFormat='{{ database_id }}',
            format='bytes'
          ),
        ]
      else
        [
          basic.timeseries(
            title='CPU Utilization',
            description=|||
              CPU utilization.

              See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
              more details.
            |||,
            query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_cpu_utilization{database_id="%s", environment="ops"} * 100' % databaseId,
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
            query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_memory_utilization{database_id="%s", environment="ops"} * 100' % databaseId,
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
            query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_disk_bytes_used{database_id="%s", environment="ops"}' % databaseId,
            legendFormat='{{ database_id }}',
            format='bytes'
          ),
        ], cols=4, rowHeight=10, startRow=1000
    )
  ),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  },
)
.overviewTrailer()
