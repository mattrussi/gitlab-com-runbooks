local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local influxdb = grafana.influxdb;
local row = grafana.row;
local thresholds = import 'thresholds.libsonnet';

local requestDurationGraph(
  title,
  description,
  query,
  measurement='rails_transaction_timings_per_action',
  limit=1000
      ) =
  grafana.graphPanel.new(
    title,
    description=description,
    datasource='influxdb-01-inf-gprd',
    format='ms',
    thresholds=[thresholds.warningLevel('gt', limit)]
  )
  .addTarget(
    influxdb.target(
      |||
        SELECT "duration_mean"
        FROM "downsampled"."%s"
        WHERE %s AND $timeFilter
        GROUP BY "action"
      ||| % [measurement, query],
      alias='$tag_action'
    )
  );

dashboard.new(
  'John H: Plan PM/Certify BE Performance',
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
.addPanel(
  row.new(title='Epics API Functionality'),
  gridPos={
    x: 0,
    y: 2,
    w: 24,
    h: 1,
  }
)
.addPanel(
  requestDurationGraph(
    'Epics API Mean Response Duration',
    'Mean request duration through the API for Epics',
    measurement='grape_transaction_timings_per_action',
    query=|||
      "action" =~ /Grape#.*epics.*/
    |||
  ), gridPos={
    x: 0,
    y: 3,
    w: 24,
    h: 8,
  }
)
