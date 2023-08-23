local panels = import './panels.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local runnersManagerMatching = import './runner_managers_matching.libsonnet';

local durationHistogram(partition=runnersManagerMatching.defaultPartition) = panels.heatmap(
  'Pending job queue duration histogram',
  runnersManagerMatching.formatQuery(|||
    sum by (le) (
      increase(gitlab_runner_job_queue_duration_seconds_bucket{environment=~"$environment", stage=~"$stage", project_jobs_running=~"$project_jobs_running", %(runnerManagersMatcher)s}[$__rate_interval])
    )
  |||, partition),
  color_mode='spectrum',
  color_colorScheme='Oranges',
  legend_show=true,
  intervalFactor=1,
);

local pendingSize =
  basic.timeseries(
    title='Pending jobs queue size',
    legendFormat='{{runner_type}}',
    format='short',
    linewidth=2,
    fill=0,
    stack=false,
    query=|||
      histogram_quantile(
        0.99,
        sum by (le, runner_type) (
          increase(gitlab_ci_queue_size_total_bucket{environment=~"$environment", stage=~"$stage"}[$__rate_interval])
        )
      )
    |||,
  );

{
  durationHistogram:: durationHistogram,
  pendingSize:: pendingSize,
}
