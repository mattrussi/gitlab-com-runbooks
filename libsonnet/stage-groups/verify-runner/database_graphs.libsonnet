local keyMetrics = import 'gitlab-dashboards/key_metrics.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local patroniService = (import 'servicemetrics/metrics-catalog.libsonnet').getService('patroni');
local panels = import './panels.libsonnet';

local patroniOverview(startRow, rowHeight) =
  keyMetrics.headlineMetricsRow(
    patroniService.type,
    selectorHash={
      type: patroniService.type,
      tier: patroniService.tier,
      environment: '$environment',
      stage: '$stage',
    },
    showApdex=true,
    showErrorRatio=true,
    showOpsRate=true,
    showSaturationCell=true,
    showDashboardListPanel=false,
    compact=true,
    rowTitle=null,
    startRow=startRow,
    rowHeight=rowHeight,
  );

local totalDeadTuples =
  basic.timeseries(
    'Total dead tuples',
    format='short',
    legendFormat='{{relname}}',
    query=|||
      pg_stat_user_tables_n_dead_tup{environment=~"$environment",stage=~"$stage",fqdn="$db_instance",datname="$db_database",relname=~"$db_top_dead_tup"}
    |||,
  );

local deadTuplesPercentage =
  basic.timeseries(
    'Dead tuples percentage',
    format='percentunit',
    legendFormat='{{relname}}',
    query=|||
      pg_stat_user_tables_n_dead_tup{environment=~"$environment",stage=~"$stage",fqdn="$db_instance",datname="$db_database",relname=~"$db_top_dead_tup"}
      /
      (
        pg_stat_user_tables_n_live_tup{environment=~"$environment",stage=~"$stage",fqdn="$db_instance",datname="$db_database",relname=~"$db_top_dead_tup"}
        +
        pg_stat_user_tables_n_dead_tup{environment=~"$environment",stage=~"$stage",fqdn="$db_instance",datname="$db_database",relname=~"$db_top_dead_tup"}
      )
    |||,
  );

local slowQueries =
  basic.timeseries(
    'Slow queries',
    format='opm',
    legendFormat='{{fqdn}}',
    query=|||
      rate(pg_slow_queries{environment=~"$environment",stage=~"$stage",fqdn=~"$db_instances"}[$__rate_interval]) * 60
    |||,
  );

local bigQueryDuration(runner_type) = panels.heatmap(
  title='%s - duration of the builds queue retrieval SQL query' % runner_type,
  query=|||
    sum by (le) (
      increase(
        gitlab_ci_queue_retrieval_duration_seconds_bucket{
          environment=~"$environment",
          stage=~"$stage",
          runner_type=~"%(runner_type)s"
        }[$__rate_interval]
      )
    )
  ||| % {
    runner_type: runner_type
  },
  description=|||
    The "big query SQL" is the SQL query GitLab uses to retrieve the jobs queue from the database. That query
    is used to add initial filtering and sorting of the queue. It's the core of jobs scheduling mechanism.

    With more and more of jobs in the ci_pending_builds table it's getting longer. At some level it may start
    affecting the whole system. The direct consequences will be seen as jobs queuing duration getting longer
    (which affects Runner's apdex) and general database slowness for the CI database.

    Therefore, observing the trend of our "big query SQL" duration is important.
  |||,
  color_mode='spectrum',
  color_colorScheme='Purples',
  legend_show=true,
  intervalFactor=1,
);

{
  patroniOverview:: patroniOverview,
  totalDeadTuples:: totalDeadTuples,
  deadTuplesPercentage:: deadTuplesPercentage,
  slowQueries:: slowQueries,
  bigQueryDuration:: bigQueryDuration,
}
