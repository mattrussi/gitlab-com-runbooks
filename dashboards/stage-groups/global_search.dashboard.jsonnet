// This file is autogenerated using scripts/update_stage_groups_dashboards.rb
// Please feel free to customize this file.
local stageGroupDashboards = import './stage-group-dashboards.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

local elasticQueueSize(title, metric) =
  basic.timeseries(
    title=title,
    yAxisLabel='Documents in queue',
    stableId='global-search-queue-size-%s' % std.asciiLower(title),
    description=|||
      The number of documents waiting to be indexed by ElasticSearch.
    |||,
    query=|||
      quantile(0.5, %(metric)s{environment="$environment", stage="$stage"})
    ||| % { metric: metric },
  );

stageGroupDashboards.dashboard('global_search')
.addPanels(
  layout.rowGrid(
    'ElasticSearch queue size',
    [
      elasticQueueSize('Overall', 'global_search_bulk_cron_queue_size'),
      elasticQueueSize('Initial', 'global_search_bulk_cron_initial_queue_size'),
    ],
    startRow=1000,
  ),
)
.stageGroupDashboardTrailer()
