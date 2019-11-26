local basic = import 'basic.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local pgbouncerCommonGraphs = import 'pgbouncer_common_graphs.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceHealth = import 'service_health.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';

local selector = 'type="pgbouncer", environment="$environment"';

dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['pgbouncer'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanels(keyMetrics.headlineMetricsRow('pgbouncer', '$stage', startRow=0))
.addPanel(serviceHealth.row('pgbouncer', '$stage'), gridPos={ x: 0, y: 500 })
.addPanel(
  row.new(title='pgbouncer Workload'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.workloadStats('patroni', startRow=2000))
.addPanel(
  row.new(title='pgbouncer Connection Pooling'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.connectionPoolingPanels('pgbouncer', 3001))
.addPanel(
  row.new(title='pgbouncer Network'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.networkStats('pgbouncer', 4001))
.addPanel(keyMetrics.keyServiceMetricsRow('pgbouncer', 'main'), gridPos={ x: 0, y: 5000 })
.addPanel(keyMetrics.keyComponentMetricsRow('pgbouncer', 'main'), gridPos={ x: 0, y: 6000 })
.addPanel(nodeMetrics.nodeMetricsDetailRow(selector), gridPos={ x: 0, y: 7000 })
.addPanel(
  saturationDetail.saturationDetailPanels(selector, components=[
    'cpu',
    'memory',
    'open_fds',
    'pgbouncer_async_pool',
    'pgbouncer_single_core',
    'pgbouncer_sync_pool',
    'single_node_cpu',
  ]),
  gridPos={ x: 0, y: 8000, w: 24, h: 1 }
)
.addPanel(capacityPlanning.capacityPlanningRow('pgbouncer', 'main'), gridPos={ x: 0, y: 9000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('pgbouncer') + platformLinks.services,
}
