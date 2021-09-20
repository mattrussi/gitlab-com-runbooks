local thresholds = import './thresholds.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local singleMetricRow = import 'key-metric-panels/single-metric-row.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local row = grafana.row;

local getLatencyPercentileForService(service) =
  if std.objectHas(service, 'contractualThresholds') && std.objectHas(service.contractualThresholds, 'apdexRatio') then
    service.contractualThresholds.apdexRatio
  else
    0.95;

local getMarkdownDetailsForSLI(sli, sliSelectorHash) =
  local items = std.prune([
    (
      if sli.description != '' then
        |||
          ### Description

          %(description)s
        ||| % {
          description: sli.description,
        }
      else
        null
    ),
    (
      if sli.hasToolingLinks() then
        // We pass the selector hash to the tooling links they may
        // be used to customize the links
        local toolingOptions = { prometheusSelectorHash: sliSelectorHash };
        |||
          ### Observability Tools

          %(links)s
        ||| % {
          links: toolingLinks.generateMarkdown(sli.getToolingLinks(), toolingOptions),
        }
      else
        null
    ),
  ]);

  std.join('\n\n', items);

local sliOverviewMatrixRow(
  serviceType,
  sli,
  startRow,
  selectorHash,
  aggregationSet,
  legendFormatPrefix,
  expectMultipleSeries
      ) =
  local selectorHashWithExtras = selectorHash { type: serviceType, component: sli.name };
  local formatConfig = {
    serviceType: serviceType,
    sliName: sli.name,
    legendFormatPrefix: if legendFormatPrefix != '' then legendFormatPrefix else sli.name,
  };

  local columns =
    singleMetricRow.row(
      serviceType=serviceType,
      aggregationSet=aggregationSet,
      selectorHash=selectorHashWithExtras,
      titlePrefix='%(sliName)s SLI' % formatConfig,
      stableIdPrefix='sli-%(sliName)s' % formatConfig,
      legendFormatPrefix='%(legendFormatPrefix)s' % formatConfig,
      expectMultipleSeries=expectMultipleSeries,
      showApdex=sli.hasApdex(),
      showErrorRatio=sli.hasErrorRate(),
      showOpsRate=true,
      includePredictions=false
    )
    +
    (
      local markdown = getMarkdownDetailsForSLI(sli, selectorHashWithExtras);
      if markdown != '' then
        [[
          grafana.text.new(
            title='Details',
            mode='markdown',
            content=markdown,
          ),
        ]]
      else
        []
    );

  layout.splitColumnGrid(columns, [7, 1], startRow=startRow);

local sliDetailLatencyPanel(
  title=null,
  serviceType=null,
  sliName=null,
  selector=null,
  aggregationLabels='',
  logBase=10,
  legendFormat='%(percentile_humanized)s %(sliName)s',
  min=0.01,
  intervalFactor=2,
      ) =
  local service = metricsCatalog.getService(serviceType);
  local sli = service.serviceLevelIndicators[sliName];
  local percentile = getLatencyPercentileForService(service);
  local formatConfig = { percentile_humanized: 'p%g' % [percentile * 100], sliName: sliName };

  basic.latencyTimeseries(
    title=(if title == null then 'Estimated %(percentile_humanized)s latency for %(sliName)s' + sliName else title) % formatConfig,
    query=sli.apdex.percentileLatencyQuery(
      percentile=percentile,
      aggregationLabels=aggregationLabels,
      selector=selector,
      rangeInterval='$__interval',
    ),
    logBase=logBase,
    legendFormat=legendFormat % formatConfig,
    min=min,
    intervalFactor=intervalFactor,
  ) + {
    thresholds: [
      thresholds.errorLevel('gt', sli.apdex.toleratedThreshold),
      thresholds.warningLevel('gt', sli.apdex.satisfiedThreshold),
    ],
  };

local sliDetailOpsRatePanel(
  title=null,
  serviceType=null,
  sliName=null,
  selector=null,
  aggregationLabels='',
  legendFormat='%(sliName)s errors',
  intervalFactor=2,
      ) =
  local service = metricsCatalog.getService(serviceType);
  local sli = service.serviceLevelIndicators[sliName];

  basic.timeseries(
    title=if title == null then 'RPS for ' + sliName else title,
    query=sli.requestRate.aggregatedRateQuery(
      aggregationLabels=aggregationLabels,
      selector=selector,
      rangeInterval='$__interval',
    ),
    legendFormat=legendFormat % { sliName: sliName },
    intervalFactor=intervalFactor,
    yAxisLabel='Requests per Second'
  );

local sliDetailErrorRatePanel(
  title=null,
  serviceType=null,
  sliName=null,
  selector=null,
  aggregationLabels='',
  legendFormat='%(sliName)s errors',
  intervalFactor=2,
      ) =
  local service = metricsCatalog.getService(serviceType);
  local sli = service.serviceLevelIndicators[sliName];

  basic.timeseries(
    title=if title == null then 'Errors for ' + sliName else title,
    query=sli.errorRate.aggregatedRateQuery(
      aggregationLabels=aggregationLabels,
      selector=selector,
      rangeInterval='$__interval',
    ),
    legendFormat=legendFormat % { sliName: sliName },
    intervalFactor=intervalFactor,
    yAxisLabel='Errors',
    decimals=2,
  );
{
  // Generates a grid/matrix of SLI data for the given service/stage
  sliMatrixForService(
    title,
    serviceType,
    aggregationSet,
    startRow,
    selectorHash,
    legendFormatPrefix='',
    expectMultipleSeries=false
  )::
    local service = metricsCatalog.getService(serviceType);
    [
      row.new(title=title, collapse=false) { gridPos: { x: 0, y: startRow, w: 24, h: 1 } },
    ] +
    std.prune(
      std.flattenArrays(
        std.mapWithIndex(
          function(i, sliName)
            sliOverviewMatrixRow(
              serviceType=serviceType,
              aggregationSet=aggregationSet,
              sli=service.serviceLevelIndicators[sliName],
              selectorHash=selectorHash { type: serviceType, component: sliName },
              startRow=startRow + 1 + i * 10,
              legendFormatPrefix=legendFormatPrefix,
              expectMultipleSeries=expectMultipleSeries,
            ), std.objectFields(service.serviceLevelIndicators)
        )
      )
    ),

  sliDetailMatrix(
    serviceType,
    sliName,
    selectorHash,
    aggregationSets,
    minLatency=0.01
  )::
    local service = metricsCatalog.getService(serviceType);
    local sli = service.serviceLevelIndicators[sliName];

    local staticLabelNames = if std.objectHas(sli, 'staticLabels') then std.objectFields(sli.staticLabels) else [];

    // Note that we always want to ignore `type` filters, since the metricsCatalog selectors will
    // already have correctly filtered labels to ensure the right values, and if we inject the type
    // we may lose metrics 'proxied' from nodes with other types
    local filteredSelectorHash = selectors.without(selectorHash, [
      'type',
    ] + staticLabelNames);

    row.new(title='🔬 %(sliName)s Service Level Indicator Detail' % { sliName: sliName }, collapse=true)
    .addPanels(
      std.flattenArrays(
        std.mapWithIndex(
          function(index, aggregationSet)
            layout.singleRow(
              std.prune(
                [
                  if sli.hasApdex() then
                    sliDetailLatencyPanel(
                      title='Estimated %(percentile_humanized)s ' + sliName + ' Latency - ' + aggregationSet.title,
                      serviceType=serviceType,
                      sliName=sliName,
                      selector=filteredSelectorHash,
                      legendFormat='%(percentile_humanized)s ' + aggregationSet.legendFormat,
                      aggregationLabels=aggregationSet.aggregationLabels,
                      min=minLatency,
                    )
                  else
                    null,

                  if aggregationSet.aggregationLabels != '' && sli.hasApdex() && std.objectHasAll(sli.apdex, 'apdexAttribution') then
                    basic.percentageTimeseries(
                      title='Apdex attribution for ' + sliName + ' Latency - ' + aggregationSet.title,
                      description='Attributes apdex downscoring',
                      query=sli.apdex.apdexAttribution(
                        aggregationLabel=aggregationSet.aggregationLabels,
                        selector=filteredSelectorHash,
                        rangeInterval='$__interval',
                      ),
                      legendFormat=aggregationSet.legendFormat % { sliName: sliName },
                      intervalFactor=3,
                      decimals=2,
                      linewidth=1,
                      fill=4,
                      stack=true,
                    )
                    .addSeriesOverride(seriesOverrides.negativeY)
                  else
                    null,

                  if sli.hasErrorRate() then
                    sliDetailErrorRatePanel(
                      title=sliName + ' Errors - ' + aggregationSet.title,
                      serviceType=serviceType,
                      sliName=sliName,
                      legendFormat=aggregationSet.legendFormat,
                      aggregationLabels=aggregationSet.aggregationLabels,
                      selector=filteredSelectorHash,
                    )
                  else
                    null,

                  if sli.hasAggregatableRequestRate() then
                    sliDetailOpsRatePanel(
                      title=sliName + ' RPS - ' + aggregationSet.title,
                      serviceType=serviceType,
                      sliName=sliName,
                      selector=filteredSelectorHash,
                      legendFormat=aggregationSet.legendFormat,
                      aggregationLabels=aggregationSet.aggregationLabels
                    )
                  else
                    null,
                ]
              ),
              startRow=index * 10
            ),
          aggregationSets
        )
      )
    ),

  autoDetailRows(serviceType, selectorHash, startRow)::
    local s = self;
    local service = metricsCatalog.getService(serviceType);
    local serviceLevelIndicators = service.listServiceLevelIndicators();
    local serviceLevelIndicatorsFiltered = std.filter(function(c) c.supportsDetails(), serviceLevelIndicators);

    layout.grid(
      std.mapWithIndex(
        function(i, sli)
          local aggregationSets =
            [
              { title: 'Overall', aggregationLabels: '', legendFormat: 'overall' },
            ] +
            std.map(function(c) { title: 'per ' + c, aggregationLabels: c, legendFormat: '{{' + c + '}}' }, sli.significantLabels);

          s.sliDetailMatrix(serviceType, sli.name, selectorHash, aggregationSets),
        serviceLevelIndicatorsFiltered
      )
      , cols=1, startRow=startRow
    ),
}
