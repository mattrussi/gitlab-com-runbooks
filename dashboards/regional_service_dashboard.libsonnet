local aggregationSets = import './aggregation-sets.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';

local dashboardForService(serviceType) =
  local formatConfig = { serviceType: serviceType };
  basic.dashboard(
    'Regional Detail',
    tags=['type:%(serviceType)s' % formatConfig, 'regional'],
  )
  .addTemplate(templates.stage)
  .addPanels(
    metricsCatalogDashboards.sliMatrixForService(
      title='🔬 Regional SLIs',
      aggregationSet=aggregationSets.regionalSLIs,
      serviceType=serviceType,
      selectorHash={ env: '$environment', environment: '$environment', type: serviceType, stage: '$stage' },
      startRow=200,
      legendFormatPrefix='{{ region }}',
      expectMultipleSeries=true
    )
  )
  .trailer();

{
  dashboardForService:: dashboardForService,
}
