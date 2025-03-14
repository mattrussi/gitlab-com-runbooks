local override = import './override.libsonnet';
local target = import './target.libsonnet';
local colors = import 'colors/colors.libsonnet';
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
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
  drawStyle='line',
  thresholdMode='absolute',
  thresholdSteps=[],
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
  ts.fieldConfig.defaults.custom.withDrawStyle(drawStyle) +
  ts.fieldConfig.defaults.custom.withLineWidth(linewidth) +
  ts.fieldConfig.defaults.custom.withPointSize(pointradius) +
  ts.fieldConfig.defaults.custom.withShowPoints(showPoints) +
  ts.options.legend.withDisplayMode(legendDisplayMode) +
  ts.options.legend.withCalcs(legendCalcs) +
  ts.options.legend.withShowLegend(legend_show) +
  ts.options.legend.withPlacement(legendPlacement) +
  ts.panelOptions.withDescription(description) +
  ts.standardOptions.withUnit(unit) +
  (if std.length(thresholdSteps) > 0 then
     ts.fieldConfig.defaults.custom.withThresholdsStyle({
       mode: 'area',
     }) +
     ts.standardOptions.thresholds.withMode(thresholdMode) +
     ts.standardOptions.thresholds.withSteps(
       if std.length(std.filter(
         function(step)
           step.value == null,
         thresholdSteps
       )) == 0 then
         [
           {
             color: '#00000000',
             value: null,
           },
         ] + thresholdSteps
       else
         thresholdSteps
     )
   else
     {})
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

local apdexTimeSeries(
  title='Apdex',
  description='Apdex is a measure of requests that complete within an acceptable threshold duration. Actual threshold vary per service or endpoint. Higher is better.',
  query='',
  legendFormat='',
  yAxisLabel='% Requests w/ Satisfactory Latency',
  interval='1m',
  intervalFactor=1,
  linewidth=2,
  min=null,
  legend_show=true,
  datasource='$PROMETHEUS_DS',
      ) =
  local formatConfig = {
    query: query,
  };
  basic(
    title,
    description=description,
    linewidth=linewidth,
    datasource=datasource,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=false,
    legend_avg=true,
    legend_alignAsTable=true,
    legend_show=legend_show,
    unit='percentunit',
  )
  .addTarget(
    target.prometheus(
      |||
        clamp_min(clamp_max(%(query)s,1),0)
      ||| % formatConfig,
      legendFormat=legendFormat,
      interval=interval,
      intervalFactor=intervalFactor
    )
  )
  .addYaxis(
    min=min,
    max=1,
    label=yAxisLabel,
  );

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
  thresholdMode='absolute',
  thresholdSteps=[],
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
    thresholdMode=thresholdMode,
    thresholdSteps=thresholdSteps,
  );

  local addPanelTarget(panel, query) =
    panel.addTarget(target.prometheus(query.query, legendFormat=query.legendFormat, interval=interval, intervalFactor=intervalFactor));

  std.foldl(addPanelTarget, queries, panel)
  .addYaxis(
    min=min,
    max=max,
    label=yAxisLabel,
  );

local latencyHistogramQuery(percentile, bucketMetric, selector, aggregator, rangeInterval) =
  |||
    histogram_quantile(%(percentile)g, sum by (%(aggregator)s, le) (
      rate(%(bucketMetric)s{%(selector)s}[%(rangeInterval)s])
    ))
  ||| % {
    percentile: percentile,
    aggregator: aggregator,
    selector: selectors.serializeHash(selector),
    bucketMetric: bucketMetric,
    rangeInterval: rangeInterval,
  };

local multiQuantileTimeSeries(
  title='Quantile latencies',
  selector='',
  legendFormat='latency',
  bucketMetric='',
  aggregators='',
  percentiles=[50, 90, 95, 99],
  legend_rightSide=false,
      ) =
  multiTimeSeries(
    title=title,
    queries=std.map(
      function(p) {
        query: latencyHistogramQuery(p / 100, bucketMetric, selector, aggregators, '$__interval'),
        legendFormat: '%s p%s' % [legendFormat, p],
      },
      percentiles
    ),
    yAxisLabel='Duration',
    format='short',
    legend_rightSide=legend_rightSide,
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
  thresholdMode='absolute',
  thresholdSteps=[],
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
    thresholdMode=thresholdMode,
    thresholdSteps=thresholdSteps,
  );

local quantileQuery(q, query) =
  |||
    quantile(%f, %s)
  ||| % [q, query];

local legendForQuantile(q, legendFormat) =
  'p%d %s' % [q * 100, legendFormat];

local quantileTimeSeries(
  query,
  quantiles=[0.99, 0.95, 0.75, 0.5, 0.25, 0.1],
  legendFormat,
  title='Multi timeseries',
  description='',
  format='short',
  interval='1m',
  intervalFactor=1,
  yAxisLabel='',
  legend_show=true,
  legend_rightSide=false,
  linewidth=2,
  max=null,
      ) =
  local queries = std.map(
    function(q) {
      query: quantileQuery(q, query),
      legendFormat: legendForQuantile(q, legendFormat),
    },
    quantiles
  );

  local panel = multiTimeSeries(
    queries=queries,
    title=title,
    description=description,
    format=format,
    interval=interval,
    intervalFactor=intervalFactor,
    yAxisLabel=yAxisLabel,
    legend_show=legend_show,
    legend_rightSide=legend_rightSide,
    linewidth=linewidth,
    max=max,
  );

  local quantileGradient = colors.linearGradient(colors.YELLOW, colors.BLUE, std.length(quantiles));

  std.foldl(
    function(panel, i)
      local q = quantiles[i];
      panel.addSeriesOverride({
        alias: 'p%d %s' % [q * 100, legendFormat],
        lines: true,
        linewidth: 1,
        fill: 1,
        color: quantileGradient[i].toString(),
      }),
    std.range(0, std.length(quantiles) - 1),
    panel
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
  thresholdMode='absolute',
  thresholdSteps=[],
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
    thresholdMode=thresholdMode,
    thresholdSteps=thresholdSteps,
  )
  .addTarget(target.prometheus(query, legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
  .addYaxis(
    min=min,
    label=yAxisLabel,
  );

local percentageTimeSeries(
  title,
  description='',
  query='',
  legendFormat='',
  yAxisLabel='Percent',
  interval='1m',
  intervalFactor=1,
  linewidth=2,
  legend_show=true,
  min=null,
  max=null,
  datasource='$PROMETHEUS_DS',
  format='percentunit',
  thresholdSteps=[],
      ) =
  local formatConfig = {
    query: query,
  };
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
    thresholdMode='percentage',
    thresholdSteps=thresholdSteps,
  )
  .addTarget(
    target.prometheus(
      |||
        clamp_min(clamp_max(%(query)s,1),0)
      ||| % formatConfig,
      legendFormat=legendFormat,
      interval=interval,
      intervalFactor=intervalFactor
    )
  )
  .addYaxis(
    min=min,
    max=max,
    label=yAxisLabel,
  );

local queueLengthTimeSeries(
  title='Timeseries',
  description='',
  query='',
  legendFormat='',
  format='short',
  interval='1m',
  intervalFactor=1,
  yAxisLabel='Queue Length',
  linewidth=2,
  datasource='$PROMETHEUS_DS',
      ) =
  basic(
    title,
    description=description,
    linewidth=linewidth,
    datasource=datasource,
    legend_show=true,
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
    min=0,
    label=yAxisLabel,
  );

local saturationTimeSeries(
  title='Saturation',
  description='',
  query='',
  legendFormat='',
  yAxisLabel='Saturation',
  interval='1m',
  intervalFactor=1,
  linewidth=2,
  legend_show=true,
  min=0,
  max=1,
  format=null,
      ) =
  percentageTimeSeries(
    title=title,
    description=description,
    query=query,
    legendFormat=legendFormat,
    yAxisLabel=yAxisLabel,
    interval=interval,
    intervalFactor=intervalFactor,
    linewidth=linewidth,
    legend_show=legend_show,
    min=min,
    max=max,
    format=format
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
  apdexTimeSeries: apdexTimeSeries,
  latencyTimeSeries: latencyTimeSeries,
  multiTimeSeries: multiTimeSeries,
  quantileTimeSeries: quantileTimeSeries,
  multiQuantileTimeSeries: multiQuantileTimeSeries,
  percentageTimeSeries: percentageTimeSeries,
  queueLengthTimeSeries: queueLengthTimeSeries,
  saturationTimeSeries: saturationTimeSeries,
  networkTrafficGraph: networkTrafficGraph,
}
