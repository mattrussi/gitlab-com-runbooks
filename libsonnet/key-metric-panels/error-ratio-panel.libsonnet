local seriesOverrides = import '../grafana/series_overrides.libsonnet';
local panel = import '../grafana/time-series/panel.libsonnet';
local target = import '../grafana/time-series/target.libsonnet';
local sliPromQL = import './sli_promql.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';

local defaultErrorRatioDescription = 'Error rates are a measure of unhandled service exceptions per second. Client errors are excluded when possible. Lower is better';

local genericErrorPanel(
  title,
  description=null,
  compact=false,
  stableId,
  primaryQueryExpr,
  legendFormat,
  linewidth=null,
  sort='decreasing',
  legend_show=null,
  selectorHash,
  fixedThreshold=null,
  shardLevelSli
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
  .addSeriesOverride(seriesOverrides.shardLevelSli)

  .addTarget(
    promQuery.target(
      primaryQueryExpr,
      legendFormat=legendFormat,
    )
  )
  .addTarget(  // Maximum error rate SLO for gitlab_service_errors:ratio metric
    promQuery.target(
      sliPromQL.errorRate.serviceErrorRateDegradationSLOQuery(selectorHash, fixedThreshold, shardLevelSli),
      interval='5m',
      legendFormat='6h Degradation SLO (5% of monthly error budget)' + (if shardLevelSli then ' - {{ shard }} shard' else ''),
    ),
  )
  .addTarget(  // Outage level SLO
    promQuery.target(
      sliPromQL.errorRate.serviceErrorRateOutageSLOQuery(selectorHash, fixedThreshold, shardLevelSli),
      interval='5m',
      legendFormat='1h Outage SLO (2% of monthly error budget)' + (if shardLevelSli then ' - {{ shard }} shard' else ''),
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

local genericErrorTimeSeriesPanel(
  title,
  description=null,
  compact=false,
  stableId,
  primaryQueryExpr,
  legendFormat,
  linewidth=null,
  sort='decreasing',
  legend_show=null,
  selectorHash,
  fixedThreshold=null,
  shardLevelSli
      ) =
  panel.basic(
    title,
    linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
    description=if description == null then defaultErrorRatioDescription else description,
    legend_show=if legend_show == null then !compact else legend_show,
    unit='percentunit',
  )
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)
  .addSeriesOverride(seriesOverrides.shardLevelSli)
  .addTarget(
    target.prometheus(
      primaryQueryExpr,
      legendFormat=legendFormat,
    )
  )
  .addTarget(  // Maximum error rate SLO for gitlab_service_errors:ratio metric
    target.prometheus(
      sliPromQL.errorRate.serviceErrorRateDegradationSLOQuery(selectorHash, fixedThreshold, shardLevelSli),
      interval='5m',
      legendFormat='6h Degradation SLO (5% of monthly error budget)' + (if shardLevelSli then ' - {{ shard }} shard' else ''),
    ),
  )
  .addTarget(  // Outage level SLO
    target.prometheus(
      sliPromQL.errorRate.serviceErrorRateOutageSLOQuery(selectorHash, fixedThreshold, shardLevelSli),
      interval='5m',
      legendFormat='1h Outage SLO (2% of monthly error budget)' + (if shardLevelSli then ' - {{ shard }} shard' else ''),
    ),
  )
  .addYaxis(
    // cannot add the format/unit to the primary axis from here anymore.
    // format='percentunit',
    min=0,
    label=if compact then '' else 'Error %',
  );
// todo: what is the point of a second axis where show is false?
// .addYaxis(
//   format='short',
//   max=1,
//   min=0,
//   show=false,
// );

local errorRatioPanel(
  title,
  sli=null,  // SLI can be null if this panel is not being used for an SLI
  aggregationSet,
  selectorHash,
  stableId,
  legendFormat=null,
  compact=false,
  includeLastWeek=true,
  expectMultipleSeries=false,
  fixedThreshold=null,
  shardLevelSli
      ) =
  local selectorHashWithExtras = selectorHash + aggregationSet.selector;

  local panel =
    genericErrorPanel(
      title,
      compact=compact,
      stableId=stableId,
      primaryQueryExpr=sliPromQL.errorRatioQuery(aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=true),
      legendFormat=legendFormat,
      linewidth=if expectMultipleSeries then 1 else 2,
      selectorHash=selectorHashWithExtras,
      fixedThreshold=fixedThreshold,
      shardLevelSli=shardLevelSli
    );

  local panelWithAverage = if !expectMultipleSeries then
    panel.addTarget(  // Primary metric (avg case)
      promQuery.target(
        sliPromQL.errorRatioQuery(aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=false),
        legendFormat=legendFormat + ' avg',
      )
    )
    .addSeriesOverride(seriesOverrides.averageCaseSeries(legendFormat + ' avg', { fillGradient: 10 }))
  else
    panel;

  local panelWithLastWeek = if !expectMultipleSeries && includeLastWeek then
    panelWithAverage.addTarget(  // Last week
      promQuery.target(
        sliPromQL.errorRatioQuery(
          aggregationSet,
          null,
          selectorHashWithExtras,
          null,
          offset='1w',
          clampToExpression=sliPromQL.errorRate.serviceErrorRateOutageSLOQuery(selectorHashWithExtras, fixedThreshold)
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
      aggregationSet.getErrorRatioConfidenceIntervalMetricForBurnRate('5m')
    else
      null;

  local panelWithConfidenceIndicator = if confidenceSLI != null then
    local confidenceSignalSeriesName = 'Error SLI (lower %s confidence boundary)' % [confidenceIntervalLevel];
    panelWithLastWeek.addTarget(
      promQuery.target(
        sliPromQL.errorRatioConfidenceQuery(confidenceIntervalLevel, aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=false),
        legendFormat=confidenceSignalSeriesName,
      )
    )
    // If there is a confidence SLI, we use that as the golden signal
    .addSeriesOverride(seriesOverrides.goldenMetric(confidenceSignalSeriesName))
    .addSeriesOverride({
      alias: legendFormat,
      color: '#082e69',
      lines: true,
    })


  else
    // If there is no confidence SLI, we use the main (non-confidence) signal as the golden signal
    panelWithLastWeek.addSeriesOverride(seriesOverrides.goldenMetric(legendFormat, { fillBelowTo: legendFormat + ' avg' }));

  panelWithConfidenceIndicator;

local errorRatioTimeSeriesPanel(
  title,
  sli=null,  // SLI can be null if this panel is not being used for an SLI
  aggregationSet,
  selectorHash,
  stableId,
  legendFormat=null,
  compact=false,
  includeLastWeek=true,
  expectMultipleSeries=false,
  fixedThreshold=null,
  shardLevelSli
      ) =
  local selectorHashWithExtras = selectorHash + aggregationSet.selector;

  local panel =
    genericErrorTimeSeriesPanel(
      title,
      compact=compact,
      stableId=stableId,
      primaryQueryExpr=sliPromQL.errorRatioQuery(aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=true),
      legendFormat=legendFormat,
      linewidth=if expectMultipleSeries then 1 else 2,
      selectorHash=selectorHashWithExtras,
      fixedThreshold=fixedThreshold,
      shardLevelSli=shardLevelSli
    );

  local panelWithAverage = if !expectMultipleSeries then
    panel.addTarget(  // Primary metric (avg case)
      target.prometheus(
        sliPromQL.errorRatioQuery(aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=false),
        legendFormat=legendFormat + ' avg',
      )
    )
    .addSeriesOverride(seriesOverrides.averageCaseSeries(legendFormat + ' avg', { fillGradient: 10 }))
  else
    panel;

  local panelWithLastWeek = if !expectMultipleSeries && includeLastWeek then
    panelWithAverage.addTarget(  // Last week
      target.prometheus(
        sliPromQL.errorRatioQuery(
          aggregationSet,
          null,
          selectorHashWithExtras,
          null,
          offset='1w',
          clampToExpression=sliPromQL.errorRate.serviceErrorRateOutageSLOQuery(selectorHashWithExtras, fixedThreshold)
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
      aggregationSet.getErrorRatioConfidenceIntervalMetricForBurnRate('5m')
    else
      null;

  local panelWithConfidenceIndicator = if confidenceSLI != null then
    local confidenceSignalSeriesName = 'Error SLI (lower %s confidence boundary)' % [confidenceIntervalLevel];
    panelWithLastWeek.addTarget(
      promQuery.target(
        sliPromQL.errorRatioConfidenceQuery(confidenceIntervalLevel, aggregationSet, null, selectorHashWithExtras, '$__interval', worstCase=false),
        legendFormat=confidenceSignalSeriesName,
      )
    )
    // If there is a confidence SLI, we use that as the golden signal
    .addSeriesOverride(seriesOverrides.goldenMetric(confidenceSignalSeriesName))
    .addSeriesOverride({
      alias: legendFormat,
      color: '#082e69',
      lines: true,
    })


  else
    // If there is no confidence SLI, we use the main (non-confidence) signal as the golden signal
    panelWithLastWeek.addSeriesOverride(seriesOverrides.goldenMetric(legendFormat, { fillBelowTo: legendFormat + ' avg' }));

  panelWithConfidenceIndicator;


{
  panel:: errorRatioPanel,
  timeSeriesPanel:: errorRatioTimeSeriesPanel,
}
