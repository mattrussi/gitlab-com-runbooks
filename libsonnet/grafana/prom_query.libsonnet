local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local p = g.query.prometheus;

{
  target(
    expr,
    format='time_series',
    intervalFactor=1,
    legendFormat='',
    datasource=null,
    interval='1m',
    instant=null,
  ):: prometheus.target(
    expr,
    format=format,
    intervalFactor=intervalFactor,
    legendFormat=legendFormat,
    datasource=datasource,
    interval=interval,
    instant=instant,
  ),

  timeSeriesTarget(
    expr,
    format='time_series',
    intervalFactor=1,
    legendFormat='',
    datasource=null,
    interval='1m',
    instant=null,
  )::
    local target =
      p.withExpr(expr) +
      p.withFormat(format) +
      p.withIntervalFactor(intervalFactor) +
      p.withLegendFormat(legendFormat) +
      p.withInterval(interval);

    local withDatasource =
      if datasource != null then
        target + p.withDatasource(datasource)
      else
        target;

    local withInstant =
      if instant != null then
        withDatasource + p.withInstant(instant)
      else
        withDatasource;

    withInstant,
}
