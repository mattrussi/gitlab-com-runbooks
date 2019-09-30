local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
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

local GITALY_PEAK_WRITE_THROUGHPUT_BYTES_PER_SECOND = 400 * 1024 * 1024;
local GITALY_PEAK_READ_THROUGHPUT_BYTES_PER_SECOND = 1200 * 1024 * 1024;
local GITALY_DISK = "sdb";

local generalGraphPanel(
  title,
  description=null,
  linewidth=2,
  sort="increasing",
) = graphPanel.new(
    title,
    linewidth=linewidth,
    fill=0,
    datasource="$PROMETHEUS_DS",
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
  )
  .addSeriesOverride(seriesOverrides.goldenMetric("/ service/"))
  .addSeriesOverride(seriesOverrides.upper)
  .addSeriesOverride(seriesOverrides.lower)
  .addSeriesOverride(seriesOverrides.upperLegacy)
  .addSeriesOverride(seriesOverrides.lowerLegacy)
  .addSeriesOverride(seriesOverrides.lastWeek)
  .addSeriesOverride(seriesOverrides.alertFiring)
  .addSeriesOverride(seriesOverrides.alertPending)
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)
  .addSeriesOverride(seriesOverrides.slo);


local activeAlertsPanel() = grafana.tablePanel.new(
    'Active Alerts',
    datasource="$PROMETHEUS_DS",
    styles=[
{
      type: "hidden",
      pattern: "Time",
      alias: "Time",
    },
{
      unit: "short",
      type: "string",
      alias: "Alert",
      decimals: 2,
      pattern: "alertname",
      mappingType: 2,
      link: true,
      linkUrl: "https://alerts.${environment}.gitlab.net/#/alerts?filter=%7Balertname%3D%22${__cell}%22%2C%20env%3D%22${environment}%22%2C%20type%3D%22${type}%22%7D",
      linkTooltip: "Open alertmanager",
    },
{
      unit: "short",
      type: "number",
      alias: "Score",
      decimals: 0,
      colors: [
        colors.warningColor,
        colors.errorColor,
        colors.criticalColor,
      ],
      colorMode: "row",
      pattern: "Value",
      thresholds: [
        "2",
        "3",
      ],
      mappingType: 1,
    },
  ],
  )
  .addTarget(  // Alert scoring
    promQuery.target(
'
      sort(
        max(
        ALERTS{environment="$environment", type="gitaly", stage="$stage", severity="critical", alertstate="firing"} * 3
        or
        ALERTS{environment="$environment", type="gitaly", stage="$stage", severity="error", alertstate="firing"} * 2
        or
        ALERTS{environment="$environment", type="gitaly", stage="$stage", severity="warn", alertstate="firing"}
        ) by (alertname, severity)
      )
      ',
      format="table",
      instant=true
    )
  );

local latencySLOPanel() = grafana.singlestat.new(
    '7d Latency SLO Error Budget',
    datasource="$PROMETHEUS_DS",
    format='percentunit',
  )
  .addTarget(
    promQuery.target(
'
        avg(avg_over_time(slo_observation_status{slo="error_ratio", environment="$environment", type="gitaly", stage="$stage"}[7d]))
      ',
      instant=true
    )
  );

local errorRateSLOPanel() = grafana.singlestat.new(
    '7d Apdex Rate SLO Error Budget',
    datasource="$PROMETHEUS_DS",
    format='percentunit',
  )
  .addTarget(
    promQuery.target(
'
        avg_over_time(slo_observation_status{slo="apdex_ratio",  environment="$environment", type="gitaly", stage="$stage"}[7d])
      ',
      instant=true
    )
  );

local readThroughput() = basic.saturationTimeseries(
  title="Average Peak Read Throughput per Node",
  description='Average Peak read throughput as a ratio of specified max (over 30s) per Node, on the Gitaly disk (' + GITALY_DISK + '). Lower is better.',
  query='
    avg_over_time(
      max_over_time(
        rate(node_disk_read_bytes_total{environment="$environment", stage="$stage", type="gitaly", device="' + GITALY_DISK + '"}[30s]) / (' + GITALY_PEAK_READ_THROUGHPUT_BYTES_PER_SECOND + ')[5m:30s]
      )[$__interval:1m]
    )
  ',
  legendFormat='{{ fqdn }}',
  interval="1m",
  intervalFactor=3,
  linewidth=1,
  legend_show=true,
);

local writeThroughput() = basic.saturationTimeseries(
  title="Average Peak Write Throughput per Node",
  description='Average Peak write throughput as a ratio of specified max (over 30s) per Node, on the Gitaly disk (' + GITALY_DISK + '). Lower is better.',
  query='
    avg_over_time(
      max_over_time(
        rate(node_disk_written_bytes_total{environment="$environment", stage="$stage", type="gitaly", device="' + GITALY_DISK + '"}[30s]) / (' + GITALY_PEAK_WRITE_THROUGHPUT_BYTES_PER_SECOND + ')[5m:30s]
     )[$__interval:1m]
    )
  ',
  legendFormat='{{ fqdn }}',
  interval="1m",
  intervalFactor=3,
  linewidth=1,
  legend_show=true,
);

dashboard.new(
  'Service Platform Metrics',
  schemaVersion=16,
  tags=['type:gitaly'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.stage)
.addTemplate(templates.sigma)
.addPanel(
row.new(title="👩‍⚕️ Service Health", collapse=true)
  .addPanel(latencySLOPanel(),
    gridPos={
      x: 0,
      y: 1,
      w: 6,
      h: 4,
  })
  .addPanel(activeAlertsPanel(),
    gridPos={
      x: 6,
      y: 1,
      w: 18,
      h: 8,
  })
  .addPanel(errorRateSLOPanel(),
    gridPos={
      x: 0,
      y: 5,
      w: 6,
      h: 4,
  }),
  gridPos={
      x: 0,
      y: 0,
      w: 24,
      h: 1,
  }
)
.addPanel(
row.new(title="🏅 Key Service Metrics"),
  gridPos={
      x: 0,
      y: 1000,
      w: 24,
      h: 1,
  }
)
.addPanels(
layout.grid([
    keyMetrics.apdexPanel('gitaly', '$stage'),
    keyMetrics.errorRatesPanel('gitaly', '$stage'),
    keyMetrics.serviceAvailabilityPanel('gitaly', '$stage'),
    keyMetrics.qpsPanel('gitaly', '$stage'),
    keyMetrics.saturationPanel('gitaly', '$stage'),
  ], startRow=1001)
)
.addPanel(
row.new(title="Node IO"),
  gridPos={
      x: 0,
      y: 2000,
      w: 24,
      h: 1,
  }
)
.addPanels(
layout.grid([
  readThroughput(),
  writeThroughput(),
  ], startRow=2001)
)

.addPanel(
keyMetrics.keyComponentMetricsRow('gitaly', '$stage'),
  gridPos={
      x: 0,
      y: 4000,
      w: 24,
      h: 1,
  }
)
.addPanel(
nodeMetrics.nodeMetricsDetailRow('environment="$environment", stage=~"|$stage", type="gitaly"'),
  gridPos={
      x: 0,
      y: 5000,
      w: 24,
      h: 1,
  }
)
.addPanel(capacityPlanning.capacityPlanningRow('gitaly', '$stage'), gridPos={ x: 0, y: 6000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('gitaly') + platformLinks.services +
  [platformLinks.dynamicLinks('Gitaly Detail', 'type:gitaly')],
}
