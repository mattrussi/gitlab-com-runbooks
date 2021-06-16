local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

local stageGroupDashboards = import './stage-group-dashboards.libsonnet';

local serviceDeskReceivedEmails() =
  basic.timeseries(
    stableId='service_desk_received_emails',
    title='Service Desk Received Emails',
    decimals=2,
    yAxisLabel='Emails',
    description=|||
      Number of emails processed by service desk handler.
    |||,
    query=|||
      sum(
          rate(
            gitlab_transaction_event_receive_email_service_desk_total{
              environment="$environment",
              stage='$stage',
            }[$__interval]
          )
      )
    |||,
  );

stageGroupDashboards.dashboard('certify', ['web', 'sidekiq'])
.addPanels(
  layout.rowGrid(
    'Service Desk Emails',
    [
      serviceDeskReceivedEmails(),
    ],
    startRow=1001
  ),
)
.stageGroupDashboardTrailer()
