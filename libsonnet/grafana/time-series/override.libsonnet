local colorScheme = import 'grafana/color_scheme.libsonnet';

local capacityComponentColors = {
  redis_clients: '#73BF69',
  single_node_cpu: '#FADE2A',
  single_threaded_cpu: '#F2495C',
  pgbouncer_async_pool: '#FA9830',
  cpu: '#B877D9',
  disk_space: '#37852E',
  memory: '#E0B301',
};

{
  upper:: {
    alias: 'upper normal',
    dashes: true,
    color: colorScheme.normalRangeColor,
    fillBelowTo: 'lower normal',
    legend: false,
    linewidth: 1,
    dashLength: 8,
    nullPointMode: 'connected',
  },
  lower:: {
    alias: 'lower normal',
    dashes: true,
    color: colorScheme.normalRangeColor,
    legend: false,
    linewidth: 1,
    dashLength: 8,
    nullPointMode: 'connected',
  },
  lastWeek:: {
    alias: 'last week',
    dashes: true,
    dashLength: 4,
    fill: 0,
    color: '#dddddd80',
    legend: true,
    linewidth: 1,
    nullPointMode: 'connected',
  },
  goldenMetric(alias, overrides={}):: self {
    alias: alias,
    color: colorScheme.primaryMetricColor,
  } + overrides,
  degradationSlo:: {
    alias: '/6h Degradation SLO \\(5% of monthly error budget\\).*/',
    color: '#FF4500',  // "Orange red"
    dashes: true,
    legend: true,
    linewidth: 2,
    dashLength: 4,
    nullPointMode: 'connected',
  },
  outageSlo:: {
    alias: '/1h Outage SLO \\(2% of monthly error budget\\).*/',
    color: '#F2495C',  // "Red"
    dashes: true,
    legend: true,
    linewidth: 4,
    dashLength: 4,
    nullPointMode: 'connected',
  },
  averageCaseSeries(alias, overrides={}):: {
    alias: alias,
    linewidth: 1,
    dashLength: 1,
    color: '#5794F280',
  } + overrides,
  shardLevelSli:: {
    alias: '/.*shard (apdex|error ratio|RPS)$/',
    color: '#E7D551',  // "Yellow"
  },
}
