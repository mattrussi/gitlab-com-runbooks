local apdexPanel = import './apdex-panel.libsonnet';
local errorRatioPanel = import './error-ratio-panel.libsonnet';
local operationRatePanel = import './operation-rate-panel.libsonnet';
local statusDescription = import './status_description.libsonnet';

local selectorToGrafanaURLParams(selectorHash) =
  local pairs = std.foldl(
    function(memo, key)
      if std.objectHas(selectorHash, key) then
        memo + ['var-' + key + '=' + selectorHash[key]]
      else
        memo,
    ['fqdn', 'component', 'type', 'stage'],
    [],
  );
  std.join('&', pairs);

// Returns a row in column format, specifically designed for consumption in
local row(
  serviceType,
  aggregationSet,
  selectorHash,
  titlePrefix,
  stableIdPrefix,
  legendFormatPrefix,
  showApdex,
  apdexDescription=null,
  showErrorRatio,
  showOpsRate,
  includePredictions=false
      ) =
  local selectorHashWithExtras = selectorHash { type: serviceType };
  local formatConfig = {
    titlePrefix: titlePrefix,
    legendFormatPrefix: legendFormatPrefix,
    stableIdPrefix: stableIdPrefix,
    aggregationId: aggregationSet.id,
    grafanaURLPairs: selectorToGrafanaURLParams(selectorHash),
  };

  (
    // SLI Component apdex
    if showApdex then
      [[
        apdexPanel.panel(
          title='%(titlePrefix)s Apdex' % formatConfig,
          aggregationSet=aggregationSet,
          serviceType=serviceType,
          selectorHash=selectorHashWithExtras,
          stableId='%(stableIdPrefix)s-apdex' % formatConfig,
          goldenMetric='%(legendFormatPrefix)s apdex' % formatConfig,
          description=apdexDescription
        )
        .addDataLink({
          url: '/d/alerts-%(aggregationId)s_multiburn_apdex?${__url_time_range}&${__all_variables}&%(grafanaURLPairs)s' % formatConfig {},
          title: '%(titlePrefix)s Apdex SLO Analysis' % formatConfig,
          targetBlank: true,
        }),
        statusDescription.apdexStatusDescriptionPanel(titlePrefix, selectorHashWithExtras, aggregationSet=aggregationSet),
      ]]
    else
      []
  )
  +
  (
    // SLI Error rate
    if showErrorRatio then
      [[
        errorRatioPanel.panel(
          '%(titlePrefix)s Error Ratio' % formatConfig,
          aggregationSet=aggregationSet,
          serviceType=serviceType,
          selectorHash=selectorHashWithExtras,
          stableId='%(stableIdPrefix)s-error-rate' % formatConfig,
          goldenMetric='%(legendFormatPrefix)s error ratio' % formatConfig,
        )
        .addDataLink({
          url: '/d/alerts-%(aggregationId)s_multiburn_error?${__url_time_range}&${__all_variables}&%(grafanaURLPairs)s' % formatConfig,
          title: '%(titlePrefix)s Error-Rate SLO Analysis' % formatConfig,
          targetBlank: true,
        }),
        statusDescription.errorRateStatusDescriptionPanel(titlePrefix, selectorHashWithExtras, aggregationSet=aggregationSet),
      ]]
    else
      []
  )
  +
  (
    // SLI request rate (mandatory, but not all are aggregatable)
    if showOpsRate then
      [[
        operationRatePanel.panel(
          '%(titlePrefix)s RPS - Requests per Second' % formatConfig,
          aggregationSet=aggregationSet,
          selectorHash=selectorHashWithExtras,
          stableId='%(stableIdPrefix)s-ops-rate' % formatConfig,
          goldenMetric='%(legendFormatPrefix)s RPS' % formatConfig,
          includePredictions=false,
          includeLastWeek=true
        ),
      ]]
    else
      []
  );

{
  row:: row,
}
