local basic = import 'grafana/basic.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';

local jobSaturationMetrics = {
  concurrent: 'gitlab_runner_concurrent',
  limit: 'gitlab_runner_limit',
};

local aggregatorLegendFormat(aggregator) = '{{ %s }}' % aggregator;

local runnerSaturation(aggregators, saturationType) =
  local serializedAggregation = aggregations.serialize(aggregators);
  basic.timeseries(
    title='Runner saturation of %(type)s by %(aggregator)s' % { aggregator: serializedAggregation, type: saturationType },
    legendFormat='%(aggregators)s' % { aggregators: std.join(' - ', std.map(aggregatorLegendFormat, aggregators)) },
    format='percentunit',
    query=|||
      sum by (%(aggregator)s) (
        gitlab_runner_jobs{environment="$environment", stage="$stage", job="runners-manager", instance=~"${runner_manager:pipe}"}
      ) / sum by (%(aggregator)s) (
        %(maxJobsMetric)s{environment="$environment", stage="$stage", job="runners-manager", instance=~"${runner_manager:pipe}"}
      )
    ||| % {
      aggregator: serializedAggregation,
      maxJobsMetric: jobSaturationMetrics[saturationType],
    }
  ).addTarget(
    promQuery.target(
      expr='0.85',
      legendFormat='Soft SLO',
    )
  ).addTarget(
    promQuery.target(
      expr='0.9',
      legendFormat='Hard SLO',
    )
  ).addSeriesOverride(
    seriesOverrides.hardSlo
  ).addSeriesOverride(
    seriesOverrides.softSlo
  );

{
  runnerSaturation:: runnerSaturation,
}
