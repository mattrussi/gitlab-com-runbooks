local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

{
  graphPanel(
    title,
    linewidth=1,
    fill=0,
    datasource='$PROMETHEUS_DS',
    description='',
    decimals=2,
    sort='desc',
    legend_show=true,
    legend_values=true,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=false,
    legend_avg=true,
    legend_alignAsTable=true,
    legend_hideEmpty=true,
    legend_rightSide=false,
    thresholds=[],
    points=false,
    pointradius=5,
    stableId=null,
    lines=true,
    stack=false,
    bars=false,
  )::
    local ts = g.panel.timeSeries;
    local datasourceType =
      if datasource == '$PROMETHEUS_DS' then
        'prometheus'
      else
        error 'unsupported datasource: ' + datasource;
    local legendCalcs = [
      if legend_min then 'min',
      if legend_max then 'max',
      if legend_avg then 'mean',
      if legend_current then 'last',
      if legend_total then 'total',
    ];
    local legendPlacement = if legend_rightSide then 'right' else 'bottom';
    local showPoints = if points then 'always' else 'never';

    ts.new(title) +
    ts.datasource.withType(datasourceType) +
    ts.datasource.withUid(datasource) +
    ts.fieldConfig.defaults.custom.withAxisGridShow(lines) +
    ts.fieldConfig.defaults.custom.withLineWidth(linewidth) +
    ts.fieldConfig.defaults.custom.withPointSize(pointradius) +
    ts.fieldConfig.defaults.custom.withShowPoints(showPoints) +
    ts.options.legend.withAsTable(legend_alignAsTable) +
    ts.options.legend.withCalcs(legendCalcs) +
    ts.options.legend.withShowLegend(legend_show) +
    ts.options.legend.withPlacement(legendPlacement) +
    ts.panelOptions.withDescription(description) +
    // bars: This doesn't appear to be used in the Timeseries panel.
    // decimals: This is set to 2 but it doesn't appear to be used.
    // fill: Aot sure what this relates to yet.
    // legend_hideEmpty: This doesn't appear to be used in the Timeseries panel.
    // legend_values: This doesn't appear to be used in the Timeseries panel.
    // sort: This doesn't appear to be in the Graph panel JSON output.
    // stableId: This doesn't appear to be used in the Timeseries panel.
    // stack: This doesn't appear to be used in the Timeseries panel.
    // threshdolds: This isn't used in the Graph panel tested, but is in the Timeseries, it may be a default that needs to be removed.
    {

    },
}
