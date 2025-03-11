// This file is autogenerated using scripts/update_stage_groups_dashboards.rb
// Please feel free to customize this file.
local stageGroupDashboards = import './stage-group-dashboards.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';
local row = grafana.row;

local useTimeSeriesPlugin = true;

local elasticQueueSize(title, metric) =
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title=title,
      yAxisLabel='Documents in queue',
      description=|||
        The number of records waiting to be synced to Elasticsearch for Global Search. These jobs are created when projects are imported or when Elasticsearch is enabled for a group in order to backfill all project data to the index. These are picked up in batches every minute. Lower is better but the batching every minute means it will not usually stay at 0. Occasional spikes are expected but sustained steady growth over a long period of time may indicate that ElasticIndexBulkCronWorker or ElasticIndexInitialBulkCronWorker is not keeping up. It may also indicate that indexing is paused in `Admin > Settings > Advanced Search`. Indexing may have been deliberately paused for maintenance.
      |||,
      query=|||
        quantile(0.5, %(metric)s{environment="$environment", stage="$stage"})
      ||| % { metric: metric },
    )
  else
    basic.timeseries(
      title=title,
      yAxisLabel='Documents in queue',
      stableId='global-search-queue-size-%s' % std.asciiLower(title),
      description=|||
        The number of records waiting to be synced to Elasticsearch for Global Search. These jobs are created when projects are imported or when Elasticsearch is enabled for a group in order to backfill all project data to the index. These are picked up in batches every minute. Lower is better but the batching every minute means it will not usually stay at 0. Occasional spikes are expected but sustained steady growth over a long period of time may indicate that ElasticIndexBulkCronWorker or ElasticIndexInitialBulkCronWorker is not keeping up. It may also indicate that indexing is paused in `Admin > Settings > Advanced Search`. Indexing may have been deliberately paused for maintenance.
      |||,
      query=|||
        quantile(0.5, %(metric)s{environment="$environment", stage="$stage"})
      ||| % { metric: metric },
    );

local searchTotalRate(title, request_type, search_type) =
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title=title,
      yAxisLabel='Global Search Request Rate',
      description=|||
        The number of Global Search search requests made during the given interval.
      |||,
      query=|||
        sum by (search_scope) (avg_over_time(application_sli_aggregation:global_search:ops:rate_5m{environment="$environment", stage="$stage" ,search_type="%(search_type)s", type="%(request_type)s", monitor="global"}[$__interval]))
      ||| % { request_type: request_type, search_type: search_type },
    )
  else
    basic.timeseries(
      title=title,
      yAxisLabel='Global Search Request Rate',
      stableId='global-search-total-rate-%s-%s' % [std.asciiLower(request_type), std.asciiLower(search_type)],
      description=|||
        The number of Global Search search requests made during the given interval.
      |||,
      query=|||
        sum by (search_scope) (avg_over_time(application_sli_aggregation:global_search:ops:rate_5m{environment="$environment", stage="$stage" ,search_type="%(search_type)s", type="%(request_type)s", monitor="global"}[$__interval]))
      ||| % { request_type: request_type, search_type: search_type },
    );

local searchErrorRate(title, request_type, search_type) =
  if useTimeSeriesPlugin then
    panel.timeSeries(
      title=title,
      yAxisLabel='Global Search Errors',
      description=|||
        The number of Global Search search requests that result in an erroneous status code or
        raise an error during the search request.
      |||,
      query=|||
        sum by (search_scope) (
          application_sli_aggregation:global_search:error:rate_5m{environment="$environment", stage="$stage", search_type="%(search_type)s", type="%(request_type)s"}
        )
        /
        sum by (search_scope) (
          application_sli_aggregation:global_search:ops:rate_5m{environment="$environment", stage="$stage" ,search_type="%(search_type)s", type="%(request_type)s"}
        )
      ||| % { request_type: request_type, search_type: search_type },
    )
  else
    basic.timeseries(
      title=title,
      yAxisLabel='Global Search Errors',
      stableId='global-search-error-rate-%s-%s' % [std.asciiLower(request_type), std.asciiLower(search_type)],
      description=|||
        The number of Global Search search requests that result in an erroneous status code or
        raise an error during the search request.
      |||,
      query=|||
        sum by (search_scope) (
          application_sli_aggregation:global_search:error:rate_5m{environment="$environment", stage="$stage", search_type="%(search_type)s", type="%(request_type)s"}
        )
        /
        sum by (search_scope) (
          application_sli_aggregation:global_search:ops:rate_5m{environment="$environment", stage="$stage" ,search_type="%(search_type)s", type="%(request_type)s"}
        )
      ||| % { request_type: request_type, search_type: search_type },
    );

stageGroupDashboards.dashboard('global_search', ['api', 'sidekiq', 'web'])
.addPanels(
  layout.rowGrid(
    'ElasticSearch queue size',
    [
      elasticQueueSize('Overall', 'search_advanced_bulk_cron_queue_size'),
      elasticQueueSize('Initial', 'search_advanced_bulk_cron_initial_queue_size'),
      elasticQueueSize('Embedding', 'search_advanced_bulk_cron_embedding_queue_size'),
    ],
    startRow=1000,
  ),
)
.addPanels(
  layout.titleRowWithPanels('Global Search - Web', layout.rows([
    layout.singleRow([
      searchErrorRate('Advanced Search Error Ratio', 'web', 'advanced'),
      searchTotalRate('Advanced Search Request Rate', 'web', 'advanced'),
    ], rowHeight=4, startRow=150),
    layout.singleRow([
      searchErrorRate('Basic Search Error Ratio', 'web', 'basic'),
      searchTotalRate('Basic Search Request Rate', 'web', 'basic'),
    ], rowHeight=4, startRow=180),
  ]), collapse=true, startRow=150),
)
.addPanels(
  layout.titleRowWithPanels('Global Search - API', layout.rows([
    layout.singleRow([
      searchErrorRate('Advanced Search Error Ratio', 'api', 'advanced'),
      searchTotalRate('Advanced Search Request Rate', 'api', 'advanced'),
    ], rowHeight=4, startRow=185),
    layout.singleRow([
      searchErrorRate('Basic Search Error Ratio', 'api', 'basic'),
      searchTotalRate('Basic Search Request Rate', 'api', 'basic'),
    ], rowHeight=4, startRow=200),
  ]), collapse=true, startRow=200),
)
.stageGroupDashboardTrailer()
