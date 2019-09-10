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

dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['pgbouncer'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanel(
  row.new(title='pgbouncer Workload'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.workloadStats('patroni', 1))
.addPanel(
  row.new(title='pgbouncer Connection Pooling'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.connectionPoolingPanels('pgbouncer', 1001))
.addPanel(
  row.new(title='pgbouncer Network'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.networkStats('pgbouncer', 2001))
.addPanel(keyMetrics.keyServiceMetricsRow('pgbouncer', 'main'), gridPos={ x: 0, y: 3000 })
.addPanel(keyMetrics.keyComponentMetricsRow('pgbouncer', 'main'), gridPos={ x: 0, y: 4000 })
.addPanel(nodeMetrics.nodeMetricsDetailRow('type="pgbouncer", environment="$environment"'), gridPos={ x: 0, y: 5000 })
.addPanel(capacityPlanning.capacityPlanningRow('pgbouncer', 'main'), gridPos={ x: 0, y: 6000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('pgbouncer') + platformLinks.services,
}
