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
      max by(runner_type) (
        gitlab_ci_current_queue_size{environment=~"$environment", stage=~"$stage"}
      )
    |||,
  );

local acceptableQueuingDurationExceeded(partition=runnersManagerMatching.byShard) =
  basic.timeseries(
    title='Acceptable job queuing duration exceeded',
    legendFormat='{{shard}}',
    format='short',
    linewidth=2,
    fill=0,
    stack=false,
    query=runnersManagerMatching.formatQuery(|||
      sum by (shard) (
        increase(
          gitlab_runner_acceptable_job_queuing_duration_exceeded_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

local queuingFailureRate(partition=runnersManagerMatching.byShard) =
  basic.timeseries(
    title='Jobs queuing failure rate',
    legendFormat='{{shard}}',
    format='percentunit',
    linewidth=2,
    fill=0,
    stack=false,
    query=runnersManagerMatching.formatQuery(|||
      sum by (shard) (
        rate(
          gitlab_runner_acceptable_job_queuing_duration_exceeded_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
      /
      sum by (shard) (
        rate(
          gitlab_runner_jobs_total{environment=~"$environment", stage=~"$stage", %(runnerManagersMatcher)s}[$__rate_interval]
        )
      )
    |||, partition),
  );

{
  durationHistogram:: durationHistogram,
  pendingSize:: pendingSize,
  acceptableQueuingDurationExceeded:: acceptableQueuingDurationExceeded,
  queuingFailureRate:: queuingFailureRate,
}
