local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local influxdb = grafana.influxdb;
local row = grafana.row;

local requestDurationGraph(title, description, query) =
  grafana.graphPanel.new(
    title,
    description=description,
    datasource='influxdb-01-inf-gprd',
    format='ms'
  )
  .addTarget(
    influxdb.target(
      |||
        SELECT "duration_mean"
        FROM "downsampled"."rails_transaction_timings_per_action"
        WHERE %(1)s AND $timeFilter
        GROUP BY "action"
      ||| % query,
      alias='$tag_action'
    )
  );

dashboard.new(
  '[TEST] John H BE Team Dashboard',
  schemaVersion=16,
  tags=['overview'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addPanel(
  row.new(title='Rails Metrics by Product Functionality'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanel(
  requestDurationGraph(
    'Viewing an Epic',
    'Mean request durations for actions involved in viewing an Epic',
    query=|||
      (
        (
          "action" =~ /Groups::EpicsController.*/
          AND "action" =~ /(show|discussions|realtime_changes)/
        )
        OR
        (
          "action" =~ /Groups::Epics::NotesController.*/
          AND "action" =~ /(index\.json)/
        )
      )
    |||
  ), gridPos={
    x: 0,
    y: 1,
    w: 12,
    h: 8,
  }
)
.addPanel(
  requestDurationGraph(
    'Interacting With an Epic',
    'Mean request duration for actions that involve interacting with an epic; updating description, adding/editing notes, linking epics and issues',
    query=|||
      (
        (
          "action" =~ /Groups::EpicsController.*/
          AND "action" =~ /(update|toggle_award_emoji)/
        ) OR (
          "action" =~ /Groups::Epics::NotesController.*/
          AND "action" =~ /(create\.json|update\.json)/
        ) OR (
          "action" =~ /Groups::EpicIssuesController.*/
          AND "action" =~ /(create\.json|update\.json|destroy\.json)/
        ) OR (
          "action" =~ /Groups::EpicLinksController.*/
          AND "action" =~ /(create\.json|update\.json|destroy\.json)/
        )
      )
    |||
  ), gridPos={
    x: 12,
    y: 1,
    w: 12,
    h: 8,
  }
)
.addPanel(
  requestDurationGraph(
    'Viewing Epics list and Roadmap',
    '',
    query=|||
      (
        (
          "action" =~ /Groups::RoadmapController.*/
          AND "action" =~ /(show)/
        ) OR (
          "action" =~ /Groups::EpicsController.*/
          AND "action" =~ /(index)/
        )
      )
    |||
  ), gridPos={
    x: 0,
    y: 1,
    w: 12,
    h: 8,
  }
)
.addPanel(
  requestDurationGraph(
    'Creating and destroying Epics',
    'Mean request durations for actions involved in creating and destroying an epic',
    query=|||
      (
        (
          "action" =~ /Groups::EpicsController.*/
          AND "action" =~ /(create|destroy)/
        )
      )
    |||
  ), gridPos={
    x: 12,
    y: 1,
    w: 12,
    h: 8,
  }
)
