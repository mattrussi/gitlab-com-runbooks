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

local legacyGitLabMonitorFQDN = 'postgres-dr-archive-01-db-gprd.c.gitlab-production.internal';

local legacyGitLabJobsOverview =
  basic.multiTimeseries(
    title='⚠ Jobs at GitLab.com ⚠',
    description=|||
      ⚠ This panel uses data gathered by GitLab Exporter with few very heavy SQL queries executed on an archive
      replica of our database. Therefore the metrics are often missing and when they are present, they are not
      fully accurate.

      YOU SHOULD NOT DEPEND ON THIS DATA and instead just treat it as a very rough estimate of what is happening
      with the jobs.

      A replacement for these metrics is under development. If you are interested, then please follow:
      https://gitlab.com/gitlab-org/gitlab/-/issues/290751.
    |||,
    linewidth=2,
    queries=[
      {
        query: 'sum(ci_pending_builds{shared_runners="yes",has_minutes="yes",fqdn="%s"})' % legacyGitLabMonitorFQDN,
        legendFormat: 'pending jobs for project with shared runners enabled',
      },
      {
        query: 'sum(ci_pending_builds{shared_runners="no",has_minutes="yes",fqdn="%s"})' % legacyGitLabMonitorFQDN,
        legendFormat: 'pending jobs for project without shared runners enabled',
      },
      {
        query: 'sum(ci_running_builds{shared_runner="yes",has_minutes="yes",fqdn="%s"})' % legacyGitLabMonitorFQDN,
        legendFormat: 'running jobs on shared runners',
      },
      {
        query: 'sum(ci_running_builds{shared_runner="yes",has_minutes="yes",fqdn="%s"})' % legacyGitLabMonitorFQDN,
        legendFormat: 'running jobs on group/project runners',
      },
      {
        query: 'sum(ci_stale_builds{fqdn="%s"})' % legacyGitLabMonitorFQDN,
        legendFormat: 'stale jobs',
      },
    ],
  ) + {
    nullPointMode: 'null as zero',
  };

{
  running:: runningJobsGraph,
  failures:: runnerJobFailuresGraph,
  started:: startedJobsGraph,
  legacyGitLabJobsOverview:: legacyGitLabJobsOverview,
}
