local aggregationSets = import './aggregation-sets.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local singleMetricRow = import 'key-metric-panels/single-metric-row.libsonnet';
local utilizationRatesPanel = import 'key-metric-panels/utilization-rates-panel.libsonnet';
local row = grafana.row;

{
  /**
   * Returns a row with key metrics for service
   */
  headlineMetricsRow(
    serviceType,
    startRow,
    rowTitle='🌡️ Aggregated Service Level Indicators (𝙎𝙇𝙄𝙨)',
    selectorHash={},
    stableIdPrefix='',
    showApdex=true,
    apdexDescription=null,
    showErrorRatio=true,
    showOpsRate=true,
    showSaturationCell=true,
    compact=false,
    rowHeight=7,
  )::
    local selectorHashWithExtras = selectorHash { type: serviceType };
    local formatConfig = { serviceType: serviceType, stableIdPrefix: stableIdPrefix };
    local columns =
      singleMetricRow.row(
        serviceType=serviceType,
        aggregationSet=aggregationSets.serviceAggregatedSLIs,
        selectorHash=selectorHashWithExtras,
        titlePrefix='%(serviceType)s Service' % formatConfig,
        stableIdPrefix='%(stableIdPrefix)sservice-%(serviceType)s' % formatConfig,
        legendFormatPrefix=serviceType,
        showApdex=showApdex,
        apdexDescription=null,
        showErrorRatio=showErrorRatio,
        showOpsRate=showOpsRate,
        includePredictions=true,
        compact=compact,
      )
      +
      (
        if showSaturationCell then
          [[
            utilizationRatesPanel.panel(
              serviceType,
              selectorHash=selectorHashWithExtras,
              compact=compact,
              stableId='%(stableIdPrefix)sservice-utilization' % formatConfig
            ),
          ]]
        else
          []
      );

    layout.grid([
      row.new(title=rowTitle, collapse=false),
    ], cols=1, rowHeight=1, startRow=startRow)
    +
    layout.splitColumnGrid(columns, [rowHeight - 1, 1], startRow=startRow + 1),
}
