local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

local stageGroupDashboards = import './stage-group-dashboards.libsonnet';

local serviceDeskReceivedEmails =
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

local serviceDeskThankYouEmails =
  basic.timeseries(
    stableId='service_desk_thank_you_email',
    title='Service Desk Outgoing Emails (New Issue)',
    decimals=2,
    yAxisLabel='Emails',
    description=|||
      Number of confirmation emails sent back to the author of new service desk issue.
    |||,
    query=|||
      sum(
        rate(
          gitlab_transaction_event_service_desk_thank_you_email_total{
            environment="$environment",
            stage='$stage',
          }[$__interval]
        )
      )
    |||,
  );

local serviceDeskNewNoteEmails =
  basic.timeseries(
    stableId='service_desk_new_note_email',
    title='Service Desk Outgoing Emails (New Comment)',
    decimals=2,
    yAxisLabel='Emails',
    description=|||
      Number of emails sent to issue participants when service desk comment is created.
    |||,
    query=|||
      sum(
        rate(
          gitlab_transaction_event_service_desk_new_note_email_total{
            environment="$environment",
            stage='$stage',
          }[$__interval]
        )
      )
    |||,
  );

local emailReceiverErrors =
  basic.timeseries(
    stableId='email_receiver_error',
    title='All Email Receiver Errors (not only Service Desk)',
    decimals=2,
    yAxisLabel='Errors',
    description=|||
      Number of received emails which could not be processed.
    |||,
    query=|||
      sum by (error) (
        rate(
          gitlab_transaction_event_email_receiver_error_total{
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
      serviceDeskReceivedEmails,
      serviceDeskThankYouEmails,
      serviceDeskNewNoteEmails,
      emailReceiverErrors,
    ],
    startRow=1001
  ),
)
.stageGroupDashboardTrailer()
