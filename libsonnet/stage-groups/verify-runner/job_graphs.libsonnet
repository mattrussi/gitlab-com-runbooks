local panels = import './panels.libsonnet';
local runnersManagerMatching = import './runner_managers_matching.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';

local aggregatorLegendFormat(aggregator) = '{{ %s }}' % aggregator;
local aggregatorsLegendFormat(aggregators) = '%s' % std.join(' - ', std.map(aggregatorLegendFormat, aggregators));

local aggregationTimeSeries(title, query, aggregators=[]) =
  local serializedAggregation = aggregations.serialize(aggregators);
  basic.timeseries(
    title=(title % serializedAggregation),
    legendFormat=aggregatorsLegendFormat(aggregators),
    format='short',
    linewidth=2,
    fill=1,
    stack=true,
    query=(query % serializedAggregation),
  );

local runningJobsGraph(aggregators=[], partition=runnersManagerMatching.defaultPartition) =
  aggregationTimeSeries(
    'Jobs running on GitLab Inc. runners (by %s)',
    runnersManagerMatching.formatQuery(|||
      sum by(%%s) (
        gitlab_runner_jobs{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}
      )
    |||, partition),
    aggregators,
  );

local runnerJobFailuresGraph(aggregators=[], partition=runnersManagerMatching.defaultPartition) =
  aggregationTimeSeries(
    'Failures on GitLab Inc. runners (by %s)',
    runnersManagerMatching.formatQuery(|||
      sum by (%%s)
      (
        increase(gitlab_runner_failed_jobs_total{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s,failure_reason=~"$runner_job_failure_reason"}[$__rate_interval])
      )
    |||, partition),
    aggregators,
  );

local startedJobsGraph(aggregators=[], partition=runnersManagerMatching.defaultPartition) =
  aggregationTimeSeries(
    'Jobs started on runners (by %s)',
    runnersManagerMatching.formatQuery(|||
      sum by(%%s) (
        increase(gitlab_runner_jobs_total{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}[$__rate_interval])
      )
    |||, partition),
    aggregators,
  ) + {
    lines: false,
    bars: true,
    targets+: [{
      expr: runnersManagerMatching.formatQuery(|||
        avg (
          increase(gitlab_runner_jobs_total{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}[$__rate_interval])
        )
      |||, partition),
      format: 'time_series',
      interval: '',
      intervalFactor: 10,
      legendFormat: 'avg',
    }],
    seriesOverrides+: [{
      alias: 'avg',
      bars: false,
      color: '#ff0000ff',
      fill: 0,
      lines: true,
      linewidth: 2,
      stack: false,
      zindex: 3,
    }],
  };

local startedJobsCounter(partition=runnersManagerMatching.defaultPartition) =
  basic.statPanel(
    title=null,
    panelTitle='Started jobs',
    color='green',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        increase(
          gitlab_runner_jobs_total{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}[1d]
        )
      )
    |||, partition),
    legendFormat='{{shard}}',
    unit='short',
    decimals=1,
    colorMode='value',
    instant=false,
    interval='1d',
    intervalFactor=1,
    reducerFunction='sum',
    justifyMode='center',
  );

local finishedJobsDurationHistogram(partition=runnersManagerMatching.defaultPartition) =
  panels.heatmap(
    'Finished job durations histogram',
    runnersManagerMatching.formatQuery(|||
      sum by (le) (
        rate(gitlab_runner_job_duration_seconds_bucket{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}[$__rate_interval])
      )
    |||, partition),
    color_mode='spectrum',
    color_colorScheme='Blues',
    legend_show=true,
    intervalFactor=1,
  );

local finishedJobsMinutesIncreaseGraph(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    title='Finished job minutes increase',
    legendFormat='{{shard}}',
    format='short',
    stack=true,
    interval='',
    intervalFactor=5,
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        increase(gitlab_runner_job_duration_seconds_sum{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}[$__rate_interval])
      )/60
    |||, partition),
  ) + {
    lines: false,
    bars: true,
    targets+: [{
      expr: runnersManagerMatching.formatQuery(|||
        avg (
          increase(gitlab_runner_job_duration_seconds_sum{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}[$__rate_interval])
        )/60
      |||, partition),
      format: 'time_series',
      interval: '',
      intervalFactor: 10,
      legendFormat: 'avg',
    }],
    seriesOverrides+: [{
      alias: 'avg',
      bars: false,
      color: '#ff0000ff',
      fill: 0,
      lines: true,
      linewidth: 2,
      stack: false,
      zindex: 3,
    }],
  };

local finishedJobsMinutesIncreaseCounter(partition=runnersManagerMatching.defaultPartition) =
  basic.statPanel(
    title=null,
    panelTitle='Finished job minutes increase',
    color='green',
    query=runnersManagerMatching.formatQuery(|||
      sum by(shard) (
        increase(gitlab_runner_job_duration_seconds_sum{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}[1d])
      )/60
    |||, partition),
    legendFormat='{{shard}}',
    unit='short',
    decimals=1,
    colorMode='value',
    instant=false,
    interval='1d',
    intervalFactor=1,
    reducerFunction='sum',
    justifyMode='center',
  );

{
  running:: runningJobsGraph,
  failures:: runnerJobFailuresGraph,
  started:: startedJobsGraph,
  finishedJobsMinutesIncrease:: finishedJobsMinutesIncreaseGraph,

  startedCounter:: startedJobsCounter,
  finishedJobsMinutesIncreaseCounter:: finishedJobsMinutesIncreaseCounter,

  finishedJobsDurationHistogram:: finishedJobsDurationHistogram,
}
