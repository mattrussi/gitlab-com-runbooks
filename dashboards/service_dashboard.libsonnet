local aggregationSets = import './aggregation-sets.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local kubeServiceDashboards = import 'kube_service_dashboards.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local systemDiagramPanel = import 'system_diagram_panel.libsonnet';
local row = grafana.row;


local defaultEnvironmentSelector = { environment: '$environment', env: '$environment' };

local listComponentThresholds(service) =
  std.prune([
    if service.serviceLevelIndicators[sliName].hasApdex() then
      ' * %s: %s' % [sliName, service.serviceLevelIndicators[sliName].apdex.describe()]
    else
      null
    for sliName in std.objectFields(service.serviceLevelIndicators)
  ]);

// This will build a description of the thresholds used in an apdex
local getApdexDescription(metricsCatalogServiceInfo) =
  std.join('  \n', [
    '_Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better._\n',
    '### Component Thresholds',
    '_Satisfactory/Tolerable_',
  ] + listComponentThresholds(metricsCatalogServiceInfo));

local headlineMetricsRow(
  serviceType,
  startRow,
  metricsCatalogServiceInfo,
  selectorHash,
  showSaturationCell,
  stableIdPrefix='',
      ) =
  local hasApdex = metricsCatalogServiceInfo.hasApdex();
  local hasErrorRate = metricsCatalogServiceInfo.hasErrorRate();
  local hasRequestRate = metricsCatalogServiceInfo.hasRequestRate();
  local selectorHashWithExtras = selectorHash { type: serviceType };

  keyMetrics.headlineMetricsRow(
    serviceType=serviceType,
    startRow=startRow,
    rowTitle='🌡️ Aggregated Service Level Indicators (𝙎𝙇𝙄𝙨)',
    selectorHash=selectorHashWithExtras,
    stableIdPrefix=stableIdPrefix,
    showApdex=hasApdex,
    apdexDescription=getApdexDescription(metricsCatalogServiceInfo),
    showErrorRatio=hasErrorRate,
    showOpsRate=hasRequestRate,
    showSaturationCell=showSaturationCell,
    rowHeight=6
  );

local overviewDashboard(
  type,
  tier,
  stage,
  environmentSelectorHash,
  saturationEnvironmentSelectorHash
      ) =
  local selectorHash = environmentSelectorHash { type: type, stage: stage };
  local selector = selectors.serializeHash(selectorHash);
  local metricsCatalogServiceInfo = metricsCatalog.getService(type);
  local saturationComponents = metricsCatalogServiceInfo.applicableSaturationTypes();

  local dashboard =
    basic.dashboard(
      'Overview',
      tags=['type:' + type, 'tier:' + tier, type, 'service overview'],
      includeEnvironmentTemplate=environmentSelectorHash == defaultEnvironmentSelector,
    )
    .addPanels(
      headlineMetricsRow(
        type,
        startRow=0,
        metricsCatalogServiceInfo=metricsCatalogServiceInfo,
        selectorHash=selectorHash,
        showSaturationCell=std.length(saturationComponents) > 0
      )
    )
    .addPanels(
      metricsCatalogDashboards.sliMatrixForService(
        title='🔬 Service Level Indicators',
        serviceType=type,
        aggregationSet=aggregationSets.globalSLIs,
        startRow=20,
        selectorHash=selectorHash
      )
    )
    .addPanels(
      metricsCatalogDashboards.autoDetailRows(type, selectorHash, startRow=100)
    )
    .addPanels(
      if metricsCatalogServiceInfo.getProvisioning().vms == true then
        [
          nodeMetrics.nodeMetricsDetailRow(selector) {
            gridPos: {
              x: 0,
              y: 300,
              w: 24,
              h: 1,
            },
          },
        ] else []
    )
    .addPanels(
      if metricsCatalogServiceInfo.getProvisioning().kubernetes == true then
        local kubeSelectorHash = { environment: '$environment', env: '$environment', stage: '$stage' };
        [
          row.new(title='☸️ Kubernetes Overview', collapse=true)
          .addPanels(kubeServiceDashboards.deploymentOverview(type, kubeSelectorHash, startRow=1)) +
          { gridPos: { x: 0, y: 400, w: 24, h: 1 } },
        ]
      else [],
    )
    .addPanels(
      if std.length(saturationComponents) > 0 then
        [
          // saturationSelector is env + type + stage
          local saturationSelector = saturationEnvironmentSelectorHash { type: type, stage: stage };
          saturationDetail.saturationDetailPanels(saturationSelector, components=saturationComponents)
          { gridPos: { x: 0, y: 500, w: 24, h: 1 } },
        ]
      else []
    );

  // Optionally add the stage variable
  local dashboardWithStage = if stage == '$stage' then dashboard.addTemplate(templates.stage) else dashboard;

  dashboardWithStage.addTemplate(templates.sigma)
  {
    overviewTrailer()::
      self
      .addPanels(
        if std.length(saturationComponents) > 0 then
          [
            capacityPlanning.capacityPlanningRow(type, stage) { gridPos: { x: 0, y: 100000 } },
          ] else []
      )
      .addPanel(
        systemDiagramPanel.systemDiagramRowForService(type),
        gridPos={ x: 0, y: 100010 }
      )
      .trailer()
      + {
        links+:
          platformLinks.triage +
          serviceCatalog.getServiceLinks(type) +
          platformLinks.services +
          [
            platformLinks.dynamicLinks(type + ' Detail', 'type:' + type),
            platformLinks.kubenetesDetail(type),
          ],
      },
  };


{
  overview(
    type,
    tier,
    stage='$stage',
    environmentSelectorHash=defaultEnvironmentSelector,
    saturationEnvironmentSelectorHash=defaultEnvironmentSelector
  )::
    overviewDashboard(
      type,
      tier,
      stage,
      environmentSelectorHash=environmentSelectorHash,
      saturationEnvironmentSelectorHash=saturationEnvironmentSelectorHash
    ),
}
