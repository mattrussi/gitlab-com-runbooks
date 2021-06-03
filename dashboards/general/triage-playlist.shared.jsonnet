local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local row = grafana.row;
local text = grafana.text;
local aggregationSets = import './aggregation-sets.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local singleMetricRow = import 'key-metric-panels/single-metric-row.libsonnet';
local utilizationRatesPanel = import 'key-metric-panels/utilization-rates-panel.libsonnet';
local row = grafana.row;
local metricsCatalog = import 'metrics-catalog.libsonnet';

local selector = { stage: 'main', env: '$environment', environment: '$environment' };

local playlistDefinitions = {
  'frontend-rails': {
    title: 'Rails Services',
    services: [
      'web',
      'api',
      'git',
      'sidekiq',
      'websockets',
    ],
  },
  'frontend-aux': {
    title: 'Other Services',
    services: [
      'ci-runners',
      'registry',
      'web-pages',
      'camoproxy',
    ],
  },
  storage: {
    title: 'Storage',
    services: [
      'gitaly',
      'praefect',
    ],
  },
  database: {
    title: 'Databases',
    services: [
      'redis',
      'redis-cache',
      'redis-sidekiq',
      'patroni',
      'pgbouncer',
    ],
  },

};

local panelsForService(index, serviceType) =
  local service = metricsCatalog.getService(serviceType);
  keyMetrics.headlineMetricsRow(
    serviceType,
    startRow=1000 + index * 100,
    rowTitle=null,
    selectorHash=selector,
    stableIdPrefix=serviceType,
    showApdex=service.hasApdex(),
    showErrorRatio=service.hasErrorRate(),
    compact=true,
    rowHeight=6,
    showDashboardListPanel=true,
  );

{
  ['playlist-' + playlistName]:
    local playlist = playlistDefinitions[playlistName];
    local panels = std.flattenArrays(
      std.mapWithIndex(panelsForService, playlist.services)
    );
    basic.dashboard(
      'Triage Playlist: ' + playlist.title,
      tags=['general'],
      refresh='30s',
    )
    .addPanels(panels)
    .trailer()
  for playlistName in std.objectFields(playlistDefinitions)
}
