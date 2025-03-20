local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local gaugePanel = grafana.gaugePanel;
local promQuery = import 'grafana/prom_query.libsonnet';
local runnersManagerMatching = import './runner_managers_matching.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';
local target = import 'grafana/time-series/target.libsonnet';
local override = import 'grafana/time-series/override.libsonnet';

local jobSaturationMetrics = {
  concurrent: 'gitlab_runner_concurrent',
  limit: 'gitlab_runner_limit',
};

local aggregatorLegendFormat(aggregator) = '{{ %s }}' % aggregator;

local runnerSaturation(aggregators, saturationType, partition=runnersManagerMatching.defaultPartition) =
  local serializedAggregation = aggregations.serialize(aggregators);
  panel.timeSeries(
    title='Runner saturation of %(type)s by %(aggregator)s' % { aggregator: serializedAggregation, type: saturationType },
    legendFormat='%(aggregators)s' % { aggregators: std.join(' - ', std.map(aggregatorLegendFormat, aggregators)) },
    format='percentunit',
    query=runnersManagerMatching.formatQuery(
      |||
        sum by (%(aggregator)s) (
          gitlab_runner_jobs{environment="$environment", stage="$stage", job=~"runners-manager|scrapeConfig/monitoring/prometheus-agent-runner", %(runnerManagersMatcher)s}
        )
        /
        sum by (%(aggregator)s) (
          %(maxJobsMetric)s{environment="$environment", stage="$stage", job=~"runners-manager|scrapeConfig/monitoring/prometheus-agent-runner", %(runnerManagersMatcher)s}
        )
      |||,
      partition,
      {
        aggregator: serializedAggregation,
        maxJobsMetric: jobSaturationMetrics[saturationType],
      },
    )
  ).addTarget(
    target.prometheus(
      expr='0.85',
      legendFormat='Soft SLO',
    )
  ).addTarget(
    target.prometheus(
      expr='0.9',
      legendFormat='Hard SLO',
    )
  ).addSeriesOverride(
    override.hardSlo
  ).addSeriesOverride(
    override.softSlo
  );

local runnerSaturationCounter(partition=runnersManagerMatching.defaultPartition) =
  gaugePanel.new(
    title='Runner managers mean saturation',
    datasource='$PROMETHEUS_DS',
    reducerFunction='mean',
    showThresholdMarkers=true,
    unit='percentunit',
    min=0,
    max=1,
    decimals=1,
    pluginVersion='7.2.0',
  )
  .addTarget(promQuery.target(
    expr=runnersManagerMatching.formatQuery(|||
      sum by(shard) (gitlab_runner_jobs{environment="$environment", stage="$stage", job=~"runners-manager|scrapeConfig/monitoring/prometheus-agent-runner", %(runnerManagersMatcher)s})
      /
      sum by(shard) (gitlab_runner_concurrent{environment="$environment", stage="$stage", job=~"runners-manager|scrapeConfig/monitoring/prometheus-agent-runner", %(runnerManagersMatcher)s})
    |||, partition),
    legendFormat='{{shard}}',
    interval='1d',
    intervalFactor=1,
  ))
  .addThresholds([
    {
      color: 'green',
      value: null,
    },
    {
      color: '#EAB839',
      value: 0.75,
    },
    {
      color: 'red',
      value: 0.9,
    },
  ]);

{
  runnerSaturation:: runnerSaturation,
  runnerSaturationCounter:: runnerSaturationCounter,
}
