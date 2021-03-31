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

local runningJobsGraph(aggregators=[]) =
  aggregationTimeSeries(
    'Jobs running on GitLab Inc. runners (by %s)',
    'sum by(%s) (gitlab_runner_jobs{instance=~"${runner_manager:pipe}"})',
    aggregators,
  );

local runnerJobFailuresGraph(aggregators=[]) =
  aggregationTimeSeries(
    'Failures on GitLab Inc. runners (by %s)',
    |||
      sum by (%s)
      (
        increase(gitlab_runner_failed_jobs_total{instance=~"${runner_manager:pipe}",failure_reason=~"$runner_job_failure_reason"}[$__interval])
      )
    |||,
    aggregators,
  );

local startedJobsGraph(aggregators=[]) =
  aggregationTimeSeries(
    'Jobs started on runners (by %s)',
    |||
      sum by(%s) (
        increase(gitlab_runner_jobs_total{instance=~"${runner_manager:pipe}"}[$__interval])
      )
    |||,
    aggregators,
  );

{
  running:: runningJobsGraph,
  failures:: runnerJobFailuresGraph,
  started:: startedJobsGraph,
}
