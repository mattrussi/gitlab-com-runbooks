local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local crCommon = import 'gitlab-dashboards/container_registry_graphs.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

basic.dashboard(
  'Database Info',
  tags=['container registry', 'docker', 'registry'],
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
.addPanel(
  row.new(title='Connection Pool'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(crCommon.dbConnPool(startRow=1))

.addPanel(
  row.new(title='CloudSQL (pre only)'),
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
      title='CPU Utilization',
      description=|||
        CPU utilization.

        See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
        more details.
      |||,
      query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_cpu_utilization{database_id=~".+:registry-db.+", environment="$environment"}',
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
      query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_memory_utilization{database_id=~".+:registry-db.+", environment="$environment"}',
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
      query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_disk_bytes_used{database_id=~".+:registry-db.+", environment="$environment"}',
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
          avg_over_time(stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_transaction_count{database_id=~".+:registry-db.+", environment="$environment"}[$__interval])
        )
      |||,
      legendFormat='{{ database_id }}',
    ),
  ], cols=3, rowHeight=10, startRow=501)
)
