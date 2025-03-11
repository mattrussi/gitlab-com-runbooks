local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';

local stageGroupDashboards = import './stage-group-dashboards.libsonnet';

local useTimeSeriesPlugin = true;

local actionCableActiveConnections() =
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title='ActionCable Active Connections',
      yAxisLabel='Connections',
      description=|||
        Number of ActionCable connections active at the time of sampling.
      |||,
      query=|||
        sum(
          action_cable_active_connections{
            environment="$environment",
            stage="$stage",
          }
        )
      |||,
    )
  else
    basic.timeseries(
      stableId='action_cable_active_connections',
      title='ActionCable Active Connections',
      decimals=2,
      yAxisLabel='Connections',
      description=|||
        Number of ActionCable connections active at the time of sampling.
      |||,
      query=|||
        sum(
          action_cable_active_connections{
            environment="$environment",
            stage="$stage",
          }
        )
      |||,
    );

local serviceDeskReceivedEmails =
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title='Service Desk Received Emails',
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
    )
  else
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
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title='Service Desk Outgoing Emails (New Issue)',
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
    )
  else
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
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title='Service Desk Outgoing Emails (New Comment)',
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
    )
  else
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
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title='All Email Receiver Errors (not only Service Desk)',
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
    )
  else
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

local serviceDeskLogLinks =
  basic.text(
    title='Service Desk Log Links',
    mode='markdown',
    content=|||
      Use the links below to see logs for specific exceptions related to incoming email.

      * [Gitlab::Email::UnknownIncomingEmail](https://log.gprd.gitlab.net/goto/a89e2320-9ee8-11ec-bd7b-c108343628c3)
      * [Gitlab::Email::AutogeneratedEmailError](https://log.gprd.gitlab.net/goto/7f24b6b0-9f08-11ec-bcd1-aba7259b6bf1)
      * [Gitlab::Email::InvalidIssueError](https://log.gprd.gitlab.net/goto/975aae60-9f08-11ec-bd7b-c108343628c3)
      * [Gitlab::Email::ProjectNotFound](https://log.gprd.gitlab.net/goto/bd1b4b00-9f08-11ec-bd7b-c108343628c3)
      * [Gitlab::Email::InvalidMergeRequestError](https://log.gprd.gitlab.net/goto/cf34c6e0-9f08-11ec-bcd1-aba7259b6bf1)
      * [Gitlab::Email::ProjectNotFound](https://log.gprd.gitlab.net/goto/ddd325c0-9f08-11ec-bcd1-aba7259b6bf1)
      * [Gitlab::Email::UserNotAuthorizedError](https://log.gprd.gitlab.net/goto/ef71cc50-9f08-11ec-bcd1-aba7259b6bf1)
      * [Gitlab::Email::UserNotFoundError](https://log.gprd.gitlab.net/goto/00fac800-9f09-11ec-bd7b-c108343628c3)
    |||,
  );

stageGroupDashboards
.dashboard('project_management')
.addPanels(
  layout.rowGrid(
    'ActionCable Connections',
    [
      actionCableActiveConnections(),
    ],
    startRow=1000
  ),
)
.addPanels(
  layout.rowGrid(
    'Service Desk Emails',
    [
      serviceDeskReceivedEmails,
      serviceDeskThankYouEmails,
      serviceDeskNewNoteEmails,
      emailReceiverErrors,
      serviceDeskLogLinks,
    ],
    startRow=2000
  )
)
.stageGroupDashboardTrailer()
