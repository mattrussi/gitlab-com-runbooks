local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

{
  connectionPanels(serviceType, startRow)::
    local formatConfig = {
      selector: selectors.serializeHash({
        environment: '$environment',
        type: serviceType,
      }),
    };

    local panels = layout.grid([
      basic.timeseries(
        title='Connections per database',
        description='The number of connections held by the database instance.',
        yAxisLabel='Connections per database',
        query=|||
          max by (database) (stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_num_backends{%(selector)s})
        ||| % formatConfig,
        legendFormat='{{ database }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Connections by status',
        description='The number of connections grouped by these statuses: idle, active, idle_in_transaction, idle_in_transaction_aborted, disabled, and fastpath_function_call.',
        yAxisLabel='Connections by status',
        query=|||
          sum by (state) (
            stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_num_backends_by_state{%(selector)s}
          ) / 60
        ||| % formatConfig,
        legendFormat='{{ state }}',
        interval='30s',
        intervalFactor=1,
      ),
      basic.timeseries(
        title='Connection wait events',
        description='The number of connections for each wait event type in a Cloud SQL for PostgreSQL instance.',
        yAxisLabel='Wait events',
        query=|||
          sum by (wait_event, wait_event_type) (
            stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_backends_in_wait{%(selector)s}
          ) / 60
        ||| % formatConfig,
        legendFormat='{{ wait_event }} {{ wait_event_type }}',
        interval='30s',
        intervalFactor=1,
      ),
    ], cols=3, rowHeight=10, startRow=startRow + 1);

    layout.titleRowWithPanels(
      title='Connections',
      collapse=true,
      startRow=startRow,
      panels=panels,
    ),

  // TODO: parity with key and advanced metrics: https://cloud.google.com/sql/docs/postgres/use-system-insights#default-metrics

  runwayPostgresDashboard(service)::
    serviceDashboard.overview(
      service,
      includeStandardEnvironmentAnnotations=false
    )
    .addPanels(self.connectionPanels(serviceType=service, startRow=1000)),
}
