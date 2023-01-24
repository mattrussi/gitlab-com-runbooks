local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local row = grafana.row;

local stageGroupDashboards = import './stage-group-dashboards.libsonnet';

local diffsAvgRenderingDuration() =
  basic.multiTimeseries(
    title='Rendering Time',
    decimals=2,
    format='s',
    yAxisLabel='',
    description=|||
      Duration spent on serializing and rendering diffs on diffs batch request
    |||,
    queries=[{
      query: |||
        sum(rate(gitlab_diffs_render_real_duration_seconds_sum[1m]))
        /
        sum(rate(gitlab_diffs_render_real_duration_seconds_count[1m]))
      |||,
      legendFormat: 'Average',
    }, {
      query: |||
        histogram_quantile(
          0.90,
          sum(
            rate(gitlab_diffs_render_real_duration_seconds_bucket[1m])
          ) by (le)
        )
      |||,
      legendFormat: '90th Percentile',
    }]
  );

local diffsAvgReorderDuration() =
  basic.multiTimeseries(
    title='Reordering Time',
    decimals=2,
    format='s',
    yAxisLabel='',
    description=|||
      Duration spent on reordering of diff files on diffs batch request
    |||,
    queries=[{
      query: |||
        sum(rate(gitlab_diffs_reorder_real_duration_seconds_sum[1m]))
        /
        sum(rate(gitlab_diffs_reorder_real_duration_seconds_count[1m]))
      |||,
      legendFormat: 'Average',
    }, {
      query: |||
        histogram_quantile(
          0.90,
          sum(
            rate(gitlab_diffs_reorder_real_duration_seconds_bucket[1m])
          ) by (le)
        )
      |||,
      legendFormat: '90th Percentile',
    }]
  );

local diffsAvgCollectionDuration() =
  basic.multiTimeseries(
    title='Collection Time',
    decimals=2,
    format='s',
    yAxisLabel='',
    description=|||
      Duration spent on querying merge request diff files on diffs batch request
    |||,
    queries=[{
      query: |||
        sum(rate(gitlab_diffs_collection_real_duration_seconds_sum[1m]))
        /
        sum(rate(gitlab_diffs_collection_real_duration_seconds_count[1m]))
      |||,
      legendFormat: 'Average',
    }, {
      query: |||
        histogram_quantile(
          0.90,
          sum(
            rate(gitlab_diffs_collection_real_duration_seconds_bucket[1m])
          ) by (le)
        )
      |||,
      legendFormat: '90th Percentile',
    }]
  );

local diffsAvgComparisonDuration() =
  basic.multiTimeseries(
    title='Comparison Time',
    decimals=2,
    format='s',
    yAxisLabel='',
    description=|||
      Duration spent on getting comparison data on diffs batch request
    |||,
    queries=[{
      query: |||
        sum(rate(gitlab_diffs_comparison_real_duration_seconds_sum[1m]))
        /
        sum(rate(gitlab_diffs_comparison_real_duration_seconds_count[1m]))
      |||,
      legendFormat: 'Average',
    }, {
      query: |||
        histogram_quantile(
          0.90,
          sum(
            rate(gitlab_diffs_comparison_real_duration_seconds_bucket[1m])
          ) by (le)
        )
      |||,
      legendFormat: '90th Percentile',
    }]
  );

local diffsAvgUnfoldablePositionsDuration() =
  basic.multiTimeseries(
    title='Unfoldable Positions Time',
    decimals=2,
    format='s',
    yAxisLabel='',
    description=|||
      Duration spent on getting unfoldable note positions on diffs batch request
    |||,
    queries=[{
      query: |||
        sum(rate(gitlab_diffs_unfoldable_positions_real_duration_seconds_sum[1m]))
        /
        sum(rate(gitlab_diffs_unfoldable_positions_real_duration_seconds_count[1m]))
      |||,
      legendFormat: 'Average',
    }, {
      query: |||
        histogram_quantile(
          0.90,
          sum(
            rate(gitlab_diffs_unfoldable_positions_real_duration_seconds_bucket[1m])
          ) by (le)
        )
      |||,
      legendFormat: '90th Percentile',
    }]
  );

local diffsAvgUnfoldDuration() =
  basic.multiTimeseries(
    title='Unfold Time',
    decimals=2,
    format='s',
    yAxisLabel='',
    description=|||
      Duration spent on unfolding positions on diffs batch request
    |||,
    queries=[{
      query: |||
        sum(rate(gitlab_diffs_unfold_real_duration_seconds_sum[1m]))
        /
        sum(rate(gitlab_diffs_unfold_real_duration_seconds_count[1m]))
      |||,
      legendFormat: 'Average',
    }, {
      query: |||
        histogram_quantile(
          0.90,
          sum(
            rate(gitlab_diffs_unfold_real_duration_seconds_bucket[1m])
          ) by (le)
        )
      |||,
      legendFormat: '90th Percentile',
    }]
  );

local diffsAvgWriteCacheDuration() =
  basic.multiTimeseries(
    title='Write Cache Time',
    decimals=2,
    format='s',
    yAxisLabel='',
    description=|||
      Duration spent on caching highlighted lines and stats on diffs batch request
    |||,
    queries=[{
      query: |||
        sum(rate(gitlab_diffs_write_cache_real_duration_seconds_sum[1m]))
        /
        sum(rate(gitlab_diffs_write_cache_real_duration_seconds_count[1m]))
      |||,
      legendFormat: 'Average',
    }, {
      query: |||
        histogram_quantile(
          0.90,
          sum(
            rate(gitlab_diffs_write_cache_real_duration_seconds_bucket[1m])
          ) by (le)
        )
      |||,
      legendFormat: '90th Percentile',
    }]
  );

local diffsAvgHighlightCacheDecorateDuration() =
  basic.multiTimeseries(
    title='Highlight Cache Decorate Time',
    decimals=2,
    format='s',
    yAxisLabel='',
    description=|||
      Duration spent on setting highlighted lines from cache on diffs batch request
    |||,
    queries=[{
      query: |||
        sum(rate(gitlab_diffs_highlight_cache_decorate_real_duration_seconds_sum[1m]))
        /
        sum(rate(gitlab_diffs_highlight_cache_decorate_real_duration_seconds_count[1m]))
      |||,
      legendFormat: 'Average',
    }, {
      query: |||
        histogram_quantile(
          0.90,
          sum(
            rate(gitlab_diffs_highlight_cache_decorate_real_duration_seconds_bucket[1m])
          ) by (le)
        )
      |||,
      legendFormat: '90th Percentile',
    }]
  );

stageGroupDashboards.dashboard('code_review')
.addPanels(
  [
    row.new(title='diffs_batch.json Metrics') { gridPos: { x: 0, y: 1001, w: 24, h: 1 } },
  ] +
  layout.grid(
    [
      diffsAvgRenderingDuration(),
      diffsAvgReorderDuration(),
      diffsAvgCollectionDuration(),
      diffsAvgComparisonDuration(),
      diffsAvgUnfoldablePositionsDuration(),
      diffsAvgUnfoldDuration(),
      diffsAvgWriteCacheDuration(),
      diffsAvgHighlightCacheDecorateDuration(),
    ],
    cols=4,
    startRow=1002
  ),
)
.stageGroupDashboardTrailer()
