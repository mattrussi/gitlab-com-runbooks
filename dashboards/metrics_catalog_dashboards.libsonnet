local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local statusDescription = import 'status_description.libsonnet';
local thresholds = import 'thresholds.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local row = grafana.row;
local defaultEnvironmentSelector = { environment: '$environment', env: '$environment' };

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
  serviceStage,
  sli,
  startRow,
  environmentSelectorHash
      ) =
  local sliSelectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: sli.name };
  local columns =
    (
      // SLI Component apdex
      if sli.hasApdex() then
        [[
          keyMetrics.sliApdexPanel(serviceType, serviceStage, sli.name, environmentSelectorHash),
          statusDescription.sliApdexStatusDescriptionPanel(sliSelectorHash),
        ]]
      else
        []
    )
    +
    (
      // SLI Error rate
      if sli.hasErrorRate() then
        [[
          keyMetrics.sliErrorRatePanel(serviceType, serviceStage, sli.name, environmentSelectorHash),
          statusDescription.sliErrorRateStatusDescriptionPanel(sliSelectorHash),
        ]]
      else
        []
    )
    +
    (
      // SLI request rate (mandatory, but not all are aggregatable)
      if sli.hasAggregatableRequestRate() then
        [[
          keyMetrics.sliOpsRatePanel(serviceType, serviceStage, sli.name, environmentSelectorHash),
        ]]
      else
        []
    )
    +
    (
      local markdown = getMarkdownDetailsForSLI(sli, sliSelectorHash);
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

local sliNodeOverviewMatrixRow(
  serviceType,
  sli,
  selectorHash,
  startRow,
  environmentSelectorHash
      ) =
  layout.singleRow(
    (
      if sli.hasApdex() then
        [
          keyMetrics.sliNodeApdexPanel(serviceType, sli.name, selectorHash, environmentSelectorHash),
        ]
      else []
    )
    +
    (
      if sli.hasErrorRate() then
        [
          keyMetrics.sliNodeErrorRateQuery(serviceType, sli.name, selectorHash, environmentSelectorHash),
        ]
      else []
    )
    +
    (
      if sli.hasAggregatableRequestRate() then
        [
          keyMetrics.sliNodeOperationRatePanel(serviceType, sli.name, selectorHash, environmentSelectorHash),
        ]
      else []
    )
    +
    (
      if sli.hasToolingLinks() then
        // We pass the selector hash to the tooling links they may
        // be used to customize the links
        local toolingOptions = { prometheusSelectorHash: selectorHash };

        [
          grafana.text.new(
            title='Tooling Links',
            mode='markdown',
            content=|||
              ### Observability Tools

              Note: some links may not have specific node-level filters applied.

              %(links)s
            ||| % {
              links: toolingLinks.generateMarkdown(sli.getToolingLinks(), toolingOptions),
            },
          ),
        ]
      else
        []
    ),
    startRow=startRow + 8
  );

{
  sliLatencyPanel(
    title=null,
    serviceType=null,
    sliName=null,
    selector=null,
    aggregationLabels='',
    logBase=10,
    legendFormat='%(percentile_humanized)s %(sliName)s',
    min=0.01,
    intervalFactor=2,
  )::
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
    },

  sliOpsRatePanel(
    title=null,
    serviceType=null,
    sliName=null,
    selector=null,
    aggregationLabels='',
    legendFormat='%(sliName)s errors',
    intervalFactor=2,
  )::
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
    ),


  sliErrorRatePanel(
    title=null,
    serviceType=null,
    sliName=null,
    selector=null,
    aggregationLabels='',
    legendFormat='%(sliName)s errors',
    intervalFactor=2,
  )::
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
      yAxisLabel='Errors'
    ),

  // Generates a grid/matrix of SLI data for the given service/stage
  sliMatrixForService(
    serviceType,
    serviceStage,
    startRow,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local service = metricsCatalog.getService(serviceType);
    [
      row.new(title='🔬 Service Level Indicators', collapse=false) { gridPos: { x: 0, y: startRow, w: 24, h: 1 } },
    ] +
    std.prune(
      std.flattenArrays(
        std.mapWithIndex(
          function(i, sliName)
            sliOverviewMatrixRow(
              serviceType,
              serviceStage,
              service.serviceLevelIndicators[sliName],
              startRow=startRow + 1 + i * 10,
              environmentSelectorHash=environmentSelectorHash,
            ), std.objectFields(service.serviceLevelIndicators)
        )
      )
    ),

  // Generates a grid of dashboards for a given service
  // using the provided selectorHash (used to select fqdns)
  //
  // environmentSelectorHash is used for environment-specific selectors, specifically the SLOs
  sliNodeOverviewMatrix(
    serviceType,
    selectorHash,
    startRow,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local service = metricsCatalog.getService(serviceType);
    [
      row.new(title='🔬 SLI/Node Level Indicators', collapse=false) { gridPos: { x: 0, y: startRow, w: 24, h: 1 } },
    ] +
    std.prune(
      std.flattenArrays(
        std.mapWithIndex(
          function(i, sliName)
            sliNodeOverviewMatrixRow(
              serviceType=serviceType,
              sli=service.serviceLevelIndicators[sliName],
              selectorHash=selectorHash { component: sliName },
              startRow=startRow + 1 + i * 10,
              environmentSelectorHash=environmentSelectorHash,
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
    local colCount =
      (if sli.hasApdex() then 1 else 0) +
      (if sli.hasAggregatableRequestRate() then 1 else 0) +
      (if sli.hasErrorRate() then 1 else 0);

    local staticLabelNames = if std.objectHas(sli, 'staticLabels') then std.objectFields(sli.staticLabels) else [];

    // Note that we always want to ignore `type` filters, since the metricsCatalog selectors will
    // already have correctly filtered labels to ensure the right values, and if we inject the type
    // we may lose metrics 'proxied' from nodes with other types
    local filteredSelectorHash = selectors.without(selectorHash, [
      'type',
    ] + staticLabelNames);

    row.new(title='🔬 %(sliName)s Service Level Indicator Detail' % { sliName: sliName }, collapse=true)
    .addPanels(
      layout.grid(
        std.prune(
          std.flattenArrays(
            std.map(
              function(aggregationSet)
                [
                  if sli.hasApdex() then
                    self.sliLatencyPanel(
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

                  if sli.hasErrorRate() then
                    self.sliErrorRatePanel(
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
                    self.sliOpsRatePanel(
                      title=sliName + ' RPS - ' + aggregationSet.title,
                      serviceType=serviceType,
                      sliName=sliName,
                      selector=filteredSelectorHash,
                      legendFormat=aggregationSet.legendFormat,
                      aggregationLabels=aggregationSet.aggregationLabels
                    )
                  else
                    null,
                ],
              aggregationSets
            )
          )
        ), cols=if colCount == 1 then 2 else colCount
      )
    ),

  autoDetailRows(serviceType, selectorHash, startRow)::
    local s = self;
    local service = metricsCatalog.getService(serviceType);
    local serviceLevelIndicators = service.getComponentsList();
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
