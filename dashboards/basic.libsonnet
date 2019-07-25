local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local graphPanel = grafana.graphPanel;
local grafana = import 'grafonnet/grafana.libsonnet';
local row = grafana.row;
local seriesOverrides = import 'series_overrides.libsonnet';

{
  queueLengthTimeseries(
    title="Timeseries",
    description="",
    query="",
    legendFormat='',
    format='short',
    interval="1m",
    intervalFactor=3,
    yAxisLabel='Queue Length',
    ):: graphPanel.new(
    title,
    description=description,
    sort="decreasing",
    linewidth=2,
    fill=0,
    datasource="$PROMETHEUS_DS",
    decimals=0,
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
  .addTarget(promQuery.target(query, legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
  .resetYaxes()
  .addYaxis(
    format=format,
    min=0,
    label=yAxisLabel,
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  ),

  saturationTimeseries(
    title="Saturation",
    description="",
    query="",
    legendFormat='',
    yAxisLabel='Saturation',
    interval="1m",
    intervalFactor=3,
    ):: graphPanel.new(
    title,
    description=description,
    sort="decreasing",
    linewidth=2,
    fill=0,
    datasource="$PROMETHEUS_DS",
    decimals=0,
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
  .addTarget(promQuery.target('clamp_min(clamp_max(' + query + ',1),0)', legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
  .resetYaxes()
  .addYaxis(
    format="percentunit",
    min=0,
    max=1,
    label=yAxisLabel,
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  ),

  latencyTimeseries(
    title="Latency",
    description="",
    query="",
    legendFormat='',
    format="s",
    yAxisLabel='Duration',
    interval="1m",
    intervalFactor=3,
    ):: graphPanel.new(
    title,
    description=description,
    sort="decreasing",
    linewidth=2,
    fill=0,
    datasource="$PROMETHEUS_DS",
    decimals=0,
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
  .addTarget(promQuery.target(query, legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
  .resetYaxes()
  .addYaxis(
    format="s",
    min=0,
    label=yAxisLabel,
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
}
