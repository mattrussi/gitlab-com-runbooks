local panels = import './panels.libsonnet';

local durationHistogram = panels.heatmap(
  'Pending job queue duration histogram',
  |||
    sum by (le) (
      rate(job_queue_duration_seconds_bucket{environment=~"$environment", jobs_running_for_project=~"$jobs_running_for_project"}[$__interval])
    )
  |||,
  intervalFactor=1,
);

{
  durationHistogram:: durationHistogram,
}
