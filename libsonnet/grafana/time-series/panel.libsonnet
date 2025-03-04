local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local ts = g.panel.timeSeries;

local basic(
  title,
  linewidth=1,
  dataSource='$PROMETHEUS_DS',
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
    if dataSource == '$PROMETHEUS_DS' then
      'prometheus'
    else
      error 'unsupported datasource: ' + dataSource;
  local legendCalcs = [
    if legend_min then 'min',
    if legend_max then 'max',
    if legend_avg then 'mean',
    if legend_current then 'lastNotNull',
    if legend_total then 'total',
  ];
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
  ts.datasource.withUid(dataSource) +
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
        properties: [
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
        ],
      }),

    addTarget(target):: self {
      targets+: [target],
    },
  };

{
  basic: basic,
}
