local sliPromQL = import './sli_promql.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';

local defaultErrorRatioDescription = 'Error rates are a measure of unhandled service exceptions per second. Client errors are excluded when possible. Lower is better';

local genericErrorPanel(
  title,
  description=null,
  compact=false,
  stableId,
  primaryQueryExpr,
  legendFormat,
  linewidth=null,
  serviceType,
  sort='decreasing',
  legend_show=null,
      ) =
  basic.graphPanel(
    title,
    linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
    description=if description == null then defaultErrorRatioDescription else description,
    sort=sort,
    legend_show=if legend_show == null then !compact else legend_show,
    stableId=stableId,
  )
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)

  .addTarget(
    promQuery.target(
      primaryQueryExpr,
      legendFormat=legendFormat,
    )
  )
  .addTarget(  // Maximum error rate SLO for gitlab_service_errors:ratio metric
    promQuery.target(
      sliPromQL.errorRate.serviceErrorRateDegradationSLOQuery(serviceType),
      interval='5m',
      legendFormat='6h Degradation SLO (5% of monthly error budget)',
    ),
  )
  .addTarget(  // Outage level SLO
    promQuery.target(
      sliPromQL.errorRate.serviceErrorRateOutageSLOQuery(serviceType),
      interval='5m',
      legendFormat='1h Outage SLO (2% of monthly error budget)',
    ),
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    min=0,
    label=if compact then '' else 'Error %',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  );

local errorRatioPanel(
  title,
  aggregationSet,
  serviceType,
  selectorHash,
  stableId,
  goldenMetric=null,
  legendFormat=null,
  compact=false,
  includeLastWeek=true
      ) =
  local goldenMetricOrLegendFormat = if goldenMetric != null then goldenMetric else legendFormat;
  local selectorHashWithExtras = selectorHash + aggregationSet.selector { type: serviceType };

  local panel =
    genericErrorPanel(
      title,
      compact=compact,
      stableId=stableId,
      primaryQueryExpr=sliPromQL.errorRatioQuery(aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=true),
      legendFormat=goldenMetricOrLegendFormat,
      serviceType=serviceType,
      linewidth=if goldenMetric != null then 2 else 1
    );

  local panelWithAverage = if goldenMetric != null then
    panel.addTarget(  // Primary metric (avg case)
      promQuery.target(
        sliPromQL.errorRatioQuery(aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=false),
        legendFormat=goldenMetric + ' avg',
      )
    )
    .addSeriesOverride(seriesOverrides.goldenMetric(goldenMetric, { fillBelowTo: goldenMetric + ' avg' }))
    .addSeriesOverride(seriesOverrides.averageCaseSeries(goldenMetric + ' avg', { fillGradient: 10 }))
  else
    panel;

  local panelWithLastWeek = if includeLastWeek then
    panelWithAverage.addTarget(  // Last week
      promQuery.target(
        sliPromQL.errorRatioQuery(aggregationSet, null, selectorHashWithExtras, null, offset='1w'),
        legendFormat='last week',
      )
    )
    .addSeriesOverride(seriesOverrides.lastWeek)
  else
    panelWithAverage;

  panelWithLastWeek;

{
  panel:: errorRatioPanel,
}
