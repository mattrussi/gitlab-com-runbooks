local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local dashboard = grafana.dashboard;
local influxdb = grafana.influxdb;
local row = grafana.row;
local thresholds = import 'thresholds.libsonnet';

local requestDurationGraphPrometheus(
  title,
  description,
  action,
  controller,
  limit=1
      ) =
  grafana.graphPanel.new(
    title,
    description=description,
    datasource='Global',
    format='s',
    thresholds=[thresholds.warningLevel('gt', limit)]
  )
  .addTarget(
    promQuery.target(
      |||
        avg_over_time(
          controller_action:gitlab_transaction_duration_seconds_sum:rate1m{env="gprd", controller=~"%s", stage="main", action=~"%s", type="web"}[$__interval]
        )
        /
        avg_over_time(
          controller_action:gitlab_transaction_duration_seconds_count:rate1m{env="gprd", controller=~"%s", stage="main", action=~"%s", type="web"}[$__interval]
        )
      ||| % [controller, action, controller, action],
      legendFormat='{{controller}}#{{action}}'
    )
  );

dashboard.new(
  'Plan Portfolio Management/Certify Backend Performance',
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
  requestDurationGraphPrometheus(
    'Creating, Updating and Destroying Epics',
    'Mean request durations for actions involved in creating, updaing and destroying Epics',
    controller='(Groups::EpicsController|Groups::Epics::NotesController)',
    action='(create|update|destroy|toggle_award_emoji).*'
  ), gridPos={
    x: 0,
    y: 1,
    w: 24,
    h: 8,
  }
)
.addPanel(
  requestDurationGraphPrometheus(
    'Listing and Viewing Epics and Roadmaps',
    'Mean request durations for actions involved in listing/viewing Epics and Roadmaps',
    controller='(Groups::EpicsController|Groups::Epics::NotesController|Groups::RoadmapController)',
    action='(show|discussions|realtime_changes|index).*'
  ), gridPos={
    x: 0,
    y: 2,
    w: 12,
    h: 8,
  }
)
.addPanel(
  requestDurationGraphPrometheus(
    'Linking issues and epics',
    'Mean request durations for actions involved in linking issues and epics',
    controller='(Groups::EpicLinksController|Groups::EpicIssuesController)',
    action='(create|destroy).*'
  ), gridPos={
    x: 12,
    y: 2,
    w: 12,
    h: 8,
  }
)
.addPanel(
  row.new(title='Epics API Functionality'),
  gridPos={
    x: 0,
    y: 3,
    w: 24,
    h: 1,
  }
)
