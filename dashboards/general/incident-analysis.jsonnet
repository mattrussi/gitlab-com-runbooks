local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceHealth = import 'service_health.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local basic = import 'basic.libsonnet';
local sliPromQL = import 'sli_promql.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';

local keyServices = serviceCatalog.findServices(function(service)
  std.objectHas(service.business.SLA, 'overall_sla_weighting') && service.business.SLA.overall_sla_weighting > 0);

local keyServiceTypes = std.map(function(service) service.name, keyServices);

local generalGraphPanel(title, description=null, linewidth=2, sort='increasing') =
  graphPanel.new(
    title,
    linewidth=linewidth,
    fill=0,
    datasource='$PROMETHEUS_DS',
    description=description,
    decimals=2,
    sort=sort,
    legend_show=true,
    legend_values=true,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=false,
    legend_avg=true,
    legend_alignAsTable=true,
    legend_hideEmpty=true,
  );

basic.dashboard(
  'Incident Overview',
  tags=['general'],
)
.addTemplate(templates.stage)
.addPanels(
  layout.horizontalLayout([
    row.new(title='Latencies'),
    [
      keyMetrics.apdexPanel(
        type,
        '$stage',
        title='%s Service Apdex Score' % [type],
      )
      for type in keyServiceTypes
    ],
    row.new(title='Error Rates'),
    [
      keyMetrics.errorRatesPanel(
        type,
        '$stage',
        title='%s Service Error Rate' % [type],
      )
      for type in keyServiceTypes
    ],
    row.new(title='RPS'),
    [
      keyMetrics.errorRatesPanel(
        type,
        '$stage',
        title='%s Service RPS' % [type],
      )
      for type in keyServiceTypes
    ],

  ], rowHeight=10)
)
.trailer()

// + {
//   links+: platformLinks.services + platformLinks.triage,
// }

