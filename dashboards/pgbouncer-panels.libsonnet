local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local pgbouncerCommonGraphs = import 'pgbouncer_common_graphs.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceDashboard = import 'service_dashboard.libsonnet';

local pgbouncer(
  type='pgbouncer'
      ) =
  serviceDashboard.overview(type)
  .addPanel(
    row.new(title='pgbouncer Workload'),
    gridPos={
      x: 0,
      y: 1000,
      w: 24,
      h: 1,
    }
  )
  .addPanels(pgbouncerCommonGraphs.workloadStats(type, startRow=2000))
  .addPanel(
    row.new(title='pgbouncer Connection Pooling'),
    gridPos={
      x: 0,
      y: 3000,
      w: 24,
      h: 1,
    }
  )
  .addPanels(pgbouncerCommonGraphs.connectionPoolingPanels(type, 3001))
  .addPanel(
    row.new(title='pgbouncer Network'),
    gridPos={
      x: 0,
      y: 4000,
      w: 24,
      h: 1,
    }
  )
  .addPanels(pgbouncerCommonGraphs.networkStats(type, 4001))
  .addPanel(
    row.new(title='pgbouncer Client Transaction Utilisation'),
    gridPos={
      x: 0,
      y: 5000,
      w: 24,
      h: 1,
    }
  );

{
  pgbouncer:: pgbouncer,
}
