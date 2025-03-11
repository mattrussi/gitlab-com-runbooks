local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';

// This file is autogenerated using scripts/update_stage_groups_dashboards.rb
// Please feel free to customize this file.
local stageGroupDashboards = import './stage-group-dashboards.libsonnet';

local useTimeSeriesPlugin = true;

local sastArtifactBuildsCompleted() =
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title='SAST Artifact Builds Completed',
      yAxisLabel='Count',
      description=|||
        Number of CI Builds completed with SAST report artifacts
      |||,
      query=|||
        sum by (status) (
          increase(
            artifact_report_sast_builds_completed_total{
              env="$environment"
            }[$__interval])
        )
      |||,
    )
  else
    basic.timeseries(
      stableId='sast_artifact_builds_completed',
      title='SAST Artifact Builds Completed',
      decimals=2,
      yAxisLabel='Count',
      description=|||
        Number of CI Builds completed with SAST report artifacts
      |||,
      query=|||
        sum by (status) (
          increase(
            artifact_report_sast_builds_completed_total{
              env="$environment"
            }[$__interval])
        )
      |||,
    );

local secretDetectionArtifactBuildsCompleted() =
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title='Secret Detection Artifact Builds Completed',
      yAxisLabel='Count',
      description=|||
        Number of CI Builds completed with Secret Detection report artifacts
      |||,
      query=|||
        sum by (status) (
          increase(
            artifact_report_secret_detection_builds_completed_total{
              env="$environment"
            }[$__interval])
        )
      |||,
    )
  else
    basic.timeseries(
      stableId='secret_detection_artifact_builds_completed',
      title='Secret Detection Artifact Builds Completed',
      decimals=2,
      yAxisLabel='Count',
      description=|||
        Number of CI Builds completed with Secret Detection report artifacts
      |||,
      query=|||
        sum by (status) (
          increase(
            artifact_report_secret_detection_builds_completed_total{
              env="$environment"
            }[$__interval])
        )
      |||,
    );


local codeQualityArtifactBuildsCompleted() =
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title='Code Quality Artifact Builds Completed',
      yAxisLabel='Count',
      description=|||
        Number of CI Builds completed with Code Quality report artifacts
      |||,
      query=|||
        sum by (status) (
          increase(
            artifact_report_codequality_builds_completed_total{
              env="$environment"
            }[$__interval])
        )
      |||,
    )
  else
    basic.timeseries(
      stableId='code_quality_artifact_builds_completed',
      title='Code Quality Artifact Builds Completed',
      decimals=2,
      yAxisLabel='Count',
      description=|||
        Number of CI Builds completed with Code Quality report artifacts
      |||,
      query=|||
        sum by (status) (
          increase(
            artifact_report_codequality_builds_completed_total{
              env="$environment"
            }[$__interval])
        )
      |||,
    );

stageGroupDashboards
.dashboard('static_analysis')
.addPanels(
  layout.rowGrid(
    'SAST Artifact Builds Completed',
    [
      sastArtifactBuildsCompleted(),
    ],
    startRow=1001,
  )
)
.addPanels(
  layout.rowGrid(
    'Secret Detection Artifact Builds Completed',
    [
      secretDetectionArtifactBuildsCompleted(),
    ],
    startRow=2001,
  )
)
.addPanels(
  layout.rowGrid(
    'Code Quality Artifact Builds Completed',
    [
      codeQualityArtifactBuildsCompleted(),
    ],
    startRow=3001,
  )
)
.stageGroupDashboardTrailer()
