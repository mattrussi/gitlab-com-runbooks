local override = import './override.libsonnet';
local target = import './target.libsonnet';
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local ts = g.panel.timeSeries;

local basic(
  title,
  linewidth=1,
  datasource='$PROMETHEUS_DS',
  description='',
  legend_show=true,
  legend_min=true,
  legend_max=true,
  legend_current=true,
  legend_total=false,
  legend_avg=true,
  legend_alignAsTable=true,
  legend_rightSide=false,
  points=false,
  pointradius=5,
  lines=true,
  unit=null,
      ) =
  local datasourceType =
    if datasource == '$PROMETHEUS_DS' then
      'prometheus'
    else
      error 'unsupported data source: ' + datasource;
  local legendCalcs = std.prune([
    if legend_min then 'min',
    if legend_max then 'max',
    if legend_avg then 'mean',
    if legend_current then 'lastNotNull',
    if legend_total then 'total',
  ]);
  local legendDisplayMode = if legend_alignAsTable then
    'table'
  else
    'list';
  local legendPlacement = if legend_rightSide then
    'right'
  else
    'bottom';
  local showPoints = if points then
    'always'
  else
    'never';

  ts.new(title) +
  ts.datasource.withType(datasourceType) +
  ts.datasource.withUid(datasource) +
  ts.fieldConfig.defaults.custom.withAxisGridShow(lines) +
  ts.fieldConfig.defaults.custom.withLineWidth(linewidth) +
  ts.fieldConfig.defaults.custom.withPointSize(pointradius) +
  ts.fieldConfig.defaults.custom.withShowPoints(showPoints) +
  ts.options.legend.withDisplayMode(legendDisplayMode) +
  ts.options.legend.withCalcs(legendCalcs) +
  ts.options.legend.withShowLegend(legend_show) +
  ts.options.legend.withPlacement(legendPlacement) +
  ts.panelOptions.withDescription(description) +
  ts.standardOptions.withUnit(unit) +
  {
    addYaxis(min=null, max=null, label=null, show=true)::
      local axisPlacement = if show then
        'left'
      else
        'hidden';

      self +
      ts.fieldConfig.defaults.custom.withAxisColorMode('text') +
      ts.fieldConfig.defaults.custom.withAxisPlacement(axisPlacement) +
      (
        if min != null then
          ts.standardOptions.withMin(min)
        else
          {}
      ) +
      (
        if max != null then
          ts.standardOptions.withMax(max)
        else
          {}
      ) +
      (
        if label != null then
          ts.fieldConfig.defaults.custom.withAxisLabel(label)
        else
          {}
      ),

    addDataLink(link)::
      self +
      ts.standardOptions.withLinksMixin(link),

    addSeriesOverride(override)::
      self +
      local matcherId =
        if std.startsWith(override.alias, '/') && std.endsWith(override.alias, '/') then
          'byRegexp'
        else
          'byName';

      ts.standardOptions.withOverridesMixin({
        matcher: {
          id: matcherId,
          options: override.alias,
        },
        properties: std.prune([
          if std.objectHas(override, 'dashes') && override.dashes then
            {
              id: 'custom.lineStyle',
              value: {
                dash: [override.dashLength],
                fill: 'dash',
              },
            },
          if std.objectHas(override, 'color') then
            {
              id: 'color',
              value: {
                fixedColor: override.color,
                mode: 'fixed',
              },
            },
          if std.objectHas(override, 'fillBelowTo') then
            {
              id: 'custom.fillBelowTo',
              value: override.fillBelowTo,
            },
          if std.objectHas(override, 'fillBelowTo') then
            {
              id: 'custom.fillOpacity',
              value: 30,
            },
          if std.objectHas(override, 'legend') then
            {
              id: 'custom.hideFrom',
              value: {
                legend: !override.legend,
                tooltip: false,
                viz: false,
              },
            },
          if std.objectHas(override, 'linewidth') then
            {
              id: 'custom.lineWidth',
              value: override.linewidth,
            },
          if std.objectHas(override, 'nullPointMode') && override.nullPointMode == 'connected' then
            {
              id: 'custom.spanNulls',
              value: true,
            },
          if std.objectHas(override, 'transform') then
            {
              id: 'custom.transform',
              value: override.transform,
            },
        ]),
      }),

    addTarget(target):: self {
      targets+: [target],
    },
  };

local multiTimeSeries(
  title='Multi timeseries',
  description='',
  queries=[],
  format='short',
  interval='1m',
  intervalFactor=1,
  yAxisLabel='',
  legend_show=true,
  legend_rightSide=false,
  linewidth=2,
  min=0,
  max=null,
  lines=true,
  datasource='$PROMETHEUS_DS',
      ) =
  local panel = basic(
    title,
    description=description,
    linewidth=linewidth,
    legend_rightSide=legend_rightSide,
    legend_show=legend_show,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=false,
    legend_avg=true,
    legend_alignAsTable=true,
    lines=lines,
    unit=format,
  );

  local addPanelTarget(panel, query) =
    panel.addTarget(target.prometheus(query.query, legendFormat=query.legendFormat, interval=interval, intervalFactor=intervalFactor));

  std.foldl(addPanelTarget, queries, panel)
  .addYaxis(
    min=min,
    max=max,
    label=yAxisLabel,
  );

local timeSeries(
  title='Timeseries',
  description='',
  query='',
  legendFormat='',
  format='short',
  interval='1m',
  intervalFactor=1,
  yAxisLabel='',
  legend_show=true,
  legend_rightSide=false,
  linewidth=2,
  min=0,
  max=null,
  lines=true,
  datasource='$PROMETHEUS_DS',
      ) =
  multiTimeSeries(
    queries=[{ query: query, legendFormat: legendFormat }],
    title=title,
    description=description,
    format=format,
    interval=interval,
    intervalFactor=intervalFactor,
    yAxisLabel=yAxisLabel,
    legend_show=legend_show,
    legend_rightSide=legend_rightSide,
    linewidth=linewidth,
    min=min,
    max=max,
    lines=lines,
    datasource=datasource,
  );

local latencyTimeSeries(
  title='Latency',
  description='',
  query='',
  legendFormat='',
  format='short',
  yAxisLabel='Duration',
  interval='1m',
  intervalFactor=1,
  legend_show=true,
  linewidth=2,
  min=0,
  datasource='$PROMETHEUS_DS',
      ) =
  basic(
    title,
    description=description,
    linewidth=linewidth,
    datasource=datasource,
    legend_show=legend_show,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=false,
    legend_avg=true,
    legend_alignAsTable=true,
    unit=format,
  )
  .addTarget(target.prometheus(query, legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
  .addYaxis(
    min=min,
    label=yAxisLabel,
  );

local networkTrafficGraph(
  title='Node Network Utilization',
  description='Network utilization',
  sendQuery=null,
  legendFormat='{{ fqdn }}',
  receiveQuery=null,
  intervalFactor=1,
  legend_show=true,
  datasource='$PROMETHEUS_DS',
      ) =
  basic(
    title,
    linewidth=1,
    description=description,
    datasource=datasource,
    legend_show=legend_show,
    legend_min=false,
    legend_max=false,
    legend_current=false,
    legend_total=false,
    legend_avg=false,
    legend_alignAsTable=false,
    unit='Bps',
  )
  .addSeriesOverride(override.networkReceive)
  .addTarget(
    target.prometheus(
      sendQuery,
      legendFormat='send ' + legendFormat,
      intervalFactor=intervalFactor,
    )
  )
  .addTarget(
    target.prometheus(
      receiveQuery,
      legendFormat='receive ' + legendFormat,
      intervalFactor=intervalFactor,
    )
  )
  .addYaxis(
    label='Network utilization',
  );

{
  basic: basic,
  timeSeries: timeSeries,
  latencyTimeSeries: latencyTimeSeries,
  networkTrafficGraph: networkTrafficGraph,
}
