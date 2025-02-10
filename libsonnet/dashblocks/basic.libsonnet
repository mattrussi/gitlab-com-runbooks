local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local ts = g.panel.timeSeries;

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
    local datasourceType =
      if datasource == '$PROMETHEUS_DS' then
        'prometheus'
      else
        error 'unsupported datasource: ' + datasource;

    ts.new(title) +
    ts.fieldConfig.defaults.custom.withLineWidth(linewidth) +
    ts.fieldConfig.defaults.custom.lineStyle.withFill(fill) +
    ts.queryOptions.withDatasource(datasourceType, datasource) +
    ts.queryOptions.withTargets([]) +
    ts.panelOptions.withDescription(description) +
    // todo: check if renderer is still valid.
    {
      renderer: 'flot',
      aliasColors: {},
    } +
    // todo: check yaxes and xaxis
    ts.fieldConfig.defaults.custom.withDrawStyle('line') +
    ts.fieldConfig.defaults.custom.lineStyle.withFill(fill) +
    ts.fieldConfig.defaults.custom.withGradientMode(0) +
    ts.fieldConfig.defaults.custom.withLineWidth(1),
}
