local sliPromQL = import '../sli_promql.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';
local target = import 'grafana/time-series/target.libsonnet';

local defaultApdexDescription = 'Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.';

local generalPanel(
  title,
  description=null,
  linewidth=3,
  legend_show=true,
      ) =
  panel.basic(
    title,
    linewidth=linewidth,
    description=if description == null then defaultApdexDescription else description,
    legend_show=legend_show,
    unit='percentunit',
  )
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)
  .addSeriesOverride(seriesOverrides.shardLevelSli);

local genericApdexPanel(
  title,
  description=null,
  compact=false,
  primaryQueryExpr,
  legendFormat,
  linewidth=null,
  legend_show=null,
  expectMultipleSeries=false,
  selectorHash,
  fixedThreshold=null,
  shardLevelSli
      ) =
  generalPanel(
    title,
    description=description,
    legend_show=if legend_show == null then !compact else legend_show,
    linewidth=if linewidth == null then if compact then 2 else 3 else linewidth,
  )
  .addTarget(  // Primary metric (worst case)
    target.prometheus(
      primaryQueryExpr,
      legendFormat=legendFormat,
    )
  )
  .addTarget(  // Min apdex score SLO for gitlab_service_errors:ratio metric
    target.prometheus(
      sliPromQL.apdex.serviceApdexDegradationSLOQuery(selectorHash, fixedThreshold, shardLevelSli),
      interval='5m',
      legendFormat='6h Degradation SLO (5% of monthly error budget)' + (if shardLevelSli then ' - {{ shard }} shard' else ''),
    ),
  )
  .addTarget(  // Double apdex SLO is Outage-level SLO
    target.prometheus(
      sliPromQL.apdex.serviceApdexOutageSLOQuery(selectorHash, fixedThreshold, shardLevelSli),
      interval='5m',
      legendFormat='1h Outage SLO (2% of monthly error budget)' + (if shardLevelSli then ' - {{ shard }} shard' else ''),
    ),
  )
  .addYaxis(
    max=1,
    label=if compact then '' else 'Apdex %',
  );

local apdexPanel(
  title,
  sli,  // SLI can be null if this panel is not being used for an SLI
  aggregationSet,
  selectorHash,
  description=null,
  legendFormat=null,
  compact=false,
  sort='increasing',
  includeLastWeek=true,
  expectMultipleSeries=false,
  fixedThreshold=null,
  shardLevelSli
      ) =
  local selectorHashWithExtras = selectorHash + aggregationSet.selector;

  local panel = genericApdexPanel(
    title,
    description=description,
    compact=compact,
    primaryQueryExpr=sliPromQL.apdexQuery(aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=true),
    legendFormat=legendFormat,
    linewidth=if expectMultipleSeries then 2 else 3,
    selectorHash=selectorHashWithExtras,
    fixedThreshold=fixedThreshold,
    shardLevelSli=shardLevelSli,
  );

  local panelWithAverage = if !expectMultipleSeries then
    panel.addTarget(  // Primary metric (avg case)
      target.prometheus(
        sliPromQL.apdexQuery(aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=false),
        legendFormat=legendFormat + ' avg',
      )
    )
    .addSeriesOverride(seriesOverrides.averageCaseSeries(legendFormat + ' avg', { fillBelowTo: legendFormat }))
  else
    panel;

  local panelWithLastWeek = if !expectMultipleSeries && includeLastWeek then
    panelWithAverage.addTarget(  // Last week
      target.prometheus(
        sliPromQL.apdexQuery(
          aggregationSet,
          null,
          selectorHashWithExtras,
          range=null,
          offset='1w',
          clampToExpression=sliPromQL.apdex.serviceApdexOutageSLOQuery(selectorHash, fixedThreshold)
        ),
        legendFormat='last week',
      )
    )
    .addSeriesOverride(seriesOverrides.lastWeek)
  else
    panelWithAverage;

  local confidenceIntervalLevel =
    if !expectMultipleSeries && sli != null && sli.usesConfidenceLevelForSLIAlerts() then
      sli.getConfidenceLevel()
    else
      null;

  // Add a confidence interval SLI if its enabled for the SLI AND
  // We aggregation set supports confidence level recording rules
  // at 5m (which is what we display SLIs at)
  local confidenceSLI =
    if confidenceIntervalLevel != null then
      aggregationSet.getApdexRatioConfidenceIntervalMetricForBurnRate('5m')
    else
      null;

  local panelWithConfidenceIndicator = if confidenceSLI != null then
    local confidenceSignalSeriesName = 'Apdex SLI (upper %s confidence boundary)' % [confidenceIntervalLevel];
    panelWithLastWeek.addTarget(
      target.prometheus(
        sliPromQL.apdexConfidenceQuery(confidenceIntervalLevel, aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=false),
        legendFormat=confidenceSignalSeriesName,
      )
    )
    // If there is a confidence SLI, we use that as the golden signal
    .addSeriesOverride(seriesOverrides.goldenMetric(confidenceSignalSeriesName))
    .addSeriesOverride({
      alias: legendFormat,
      color: '#082e6980',
      lines: true,
    })
  else
    // If there is no confidence SLI, we use the main (non-confidence) signal as the golden signal
    panelWithLastWeek.addSeriesOverride(seriesOverrides.goldenMetric(legendFormat));

  panelWithConfidenceIndicator;

{
  panel:: apdexPanel,
}
