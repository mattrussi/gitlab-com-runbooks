local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local ts = g.panel.timeSeries;

// bars: This doesn't appear to be used in the Timeseries panel.
// decimals: This is set to 2 but it doesn't appear to be used.
// fill: Not sure what this relates to yet.
// legend_hideEmpty: This doesn't appear to be used in the Timeseries panel.
// legend_values: This doesn't appear to be used in the Timeseries panel.
// sort: This doesn't appear to be in the Graph panel JSON output.
// stableId: This doesn't appear to be used in the Timeseries panel.
// stack: This doesn't appear to be used in the Timeseries panel.
// threshdolds: This isn't used in the Graph panel tested, but is in the Timeseries, it may be a default that needs to be removed.

{
  timeSeriesPanel(
    title,
    linewidth=1,
    description='',
    dataSource='$PROMETHEUS_DS',
    legend_show=true,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=true,
    legend_avg=true,
    legend_alignAsTable=true,
    legend_rightSide=false,
    points=false,
    pointradius=5,
    lines=true,
  )::
    local datasourceType =
      if dataSource == '$PROMETHEUS_DS' then
        'prometheus'
      else
        error 'unsupported datasource: ' + dataSource;
    local legendCalcs = [
      if legend_min then 'min',
      if legend_max then 'max',
      if legend_avg then 'mean',
      if legend_current then 'last',
      if legend_total then 'total',
    ];
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
    ts.options.legend.withAsTable(legend_alignAsTable) +
    ts.options.legend.withCalcs(legendCalcs) +
    ts.options.legend.withShowLegend(legend_show) +
    ts.options.legend.withPlacement(legendPlacement) +
    ts.panelOptions.withDescription(description),

  addSeriesOverride(override):: self {
    local matcherId =
      if std.startsWith(override.alias, '/') && std.endsWith(override.alias, '/') then
        'byRegexp'
      else
        'name',

    overrides+: ts.standardOptions.withOverrides(
      {
        matcher: {
          id: matcherId,
          options: override.alias,
        },
        properties: [
          if override.color then
            {
              id: 'color',
              value: {
                fixedColor: override.color,
                mode: 'fixed',
              },
            },
        ],
      },
    ),
  },

  addTarget(target):: self {
    targets+: ts.queryOptions.withTargets({

    }),
  },
}
