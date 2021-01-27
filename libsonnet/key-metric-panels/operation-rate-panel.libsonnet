local sliPromQL = import './sli_promql.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';

local defaultOperationRateDescription = 'The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier.';

local genericOperationRatePanel(
  title,
  description=null,
  compact=false,
  stableId,
  linewidth=null,
  sort='decreasing',
  legend_show=null,
      ) =
  basic.graphPanel(
    title,
    linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
    description=if description == null then defaultOperationRateDescription else description,
    sort=sort,
    legend_show=if legend_show == null then !compact else legend_show,
    stableId=stableId,
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    min=0,
    label=if compact then '' else 'Operations per Second',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  );

local operationRatePanel(
  title,
  aggregationSet,
  selectorHash,
  stableId,
  goldenMetric=null,
  legendFormat=null,
  compact=false,
  includePredictions=false,
  includeLastWeek=true
      ) =
  local goldenMetricOrLegendFormat = if goldenMetric != null then goldenMetric else legendFormat;
  local selectorHashWithExtras = selectorHash + aggregationSet.selector;

  local panel =
    genericOperationRatePanel(
      title,
      compact=compact,
      stableId=stableId,
    )
    .addTarget(  // Primary metric
      promQuery.target(
        sliPromQL.opsRateQuery(aggregationSet, selectorHashWithExtras, range='$__interval'),
        legendFormat=goldenMetricOrLegendFormat,
      )
    );

  local panelWithSeriesOverrides = if goldenMetric != null then
    panel.addSeriesOverride(seriesOverrides.goldenMetric(goldenMetric))
  else
    panel;

  local panelWithLastWeek = if includeLastWeek then
    panelWithSeriesOverrides
    .addTarget(  // Last week
      promQuery.target(
        sliPromQL.opsRateQuery(aggregationSet, selectorHashWithExtras, range=null, offset='1w'),
        legendFormat='last week',
      )
    )
    .addSeriesOverride(seriesOverrides.lastWeek)
  else
    panelWithSeriesOverrides;

  local panelWithPredictions = if includePredictions then
    panelWithLastWeek
    .addTarget(
      promQuery.target(
        sliPromQL.opsRate.serviceOpsRatePrediction(selectorHashWithExtras, 2),
        legendFormat='upper normal',
      ),
    )
    .addTarget(
      promQuery.target(
        sliPromQL.opsRate.serviceOpsRatePrediction(selectorHashWithExtras, -2),
        legendFormat='lower normal',
      ),
    )
    .addSeriesOverride(seriesOverrides.upper)
    .addSeriesOverride(seriesOverrides.lower)
  else
    panelWithLastWeek;

  panelWithPredictions;

{
  panel:: operationRatePanel,
}
