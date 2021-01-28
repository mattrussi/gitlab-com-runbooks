local aggregationSets = import './aggregation-sets.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local singleMetricRow = import 'key-metric-panels/single-metric-row.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';

local dashboardForService(serviceType) =
  local metricsCatalogServiceInfo = metricsCatalog.getService('gitaly');
  local formatConfig = { serviceType: serviceType };
  local selectorHash = { env: '$environment', environment: '$environment', type: serviceType, stage: '$stage' };

  local headlineRow =
    singleMetricRow.row(
      serviceType=serviceType,
      aggregationSet=aggregationSets.serviceRegionalAggregatedSLIs,
      selectorHash=selectorHash,
      titlePrefix='Regional Service Aggregated ',
      stableIdPrefix='service-regional-%(serviceType)s' % formatConfig,
      legendFormatPrefix='{{ region }}',
      showApdex=metricsCatalogServiceInfo.hasApdex(),
      showErrorRatio=metricsCatalogServiceInfo.hasErrorRate(),
      showOpsRate=true,
      expectMultipleSeries=true
    );

  basic.dashboard(
    'Regional Detail',
    tags=['type:%(serviceType)s' % formatConfig, 'regional'],
  )
  .addTemplate(templates.stage)
  .addPanels(
    layout.splitColumnGrid(headlineRow, [7, 1], startRow=10),
  )
  .addPanels(
    metricsCatalogDashboards.sliMatrixForService(
      title='🔬 Regional SLIs',
      aggregationSet=aggregationSets.regionalSLIs,
      serviceType=serviceType,
      selectorHash=selectorHash,
      startRow=1000,
      legendFormatPrefix='{{ region }}',
      expectMultipleSeries=true
    )
  )
  .trailer();

{
  dashboardForService:: dashboardForService,
}
