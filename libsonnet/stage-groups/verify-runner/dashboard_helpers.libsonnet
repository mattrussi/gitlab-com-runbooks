local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local prebuiltTemplates = import 'grafana/templates.libsonnet';
local runnersService = (import 'metrics-catalog.libsonnet').getService('ci-runners');
local keyMetrics = import 'key_metrics.libsonnet';
local platformLinks = import '../../../dashboards/platform_links.libsonnet';

local dashboardFilters = import './dashboard_filters.libsonnet';

local runnerServiceType = runnersService.type;

local underConstructionNote = layout.singleRow(
  [
    grafana.text.new(
      title='Under construction',
      mode='markdown',
      content=|||
        🚧 🦺 This dashboard is currently under construction 🦺 🚧

        Please come back later 🙂
      |||,
    ),
  ],
  rowHeight=3,
  startRow=0
);

local commonFilters = [
  dashboardFilters.shard,
  dashboardFilters.runnerManager,
];

local runnerServiceDashboardsLinks = [
  platformLinks.dynamicLinks('%s Detail' % runnerServiceType, 'type:%s' % runnerServiceType),
];

local dashboard(title, tags=[], time_from='now-3h/m') =
  basic.dashboard(
    title,
    tags=[
      'type:%s' % runnerServiceType,
      'managed',
    ] + tags,
    editable=true,
    time_from='now-12h/m',
    time_to='now/m',
    refresh='1m',
    graphTooltip='shared_crosshair',
    includeStandardEnvironmentAnnotations=true,
    includeEnvironmentTemplate=true,
  )
  .addTemplate(prebuiltTemplates.stage)
  .addTemplates(commonFilters)
  .trailer() + {
    links+: runnerServiceDashboardsLinks,
    addOverviewPanels(
      startRow=1000,
      showApdex=true,
      showErrorRatio=true,
      showOpsRate=false,
      showSaturationCell=true,
      showDashboardListPanel=false,
      compact=true,
      rowHeight=6,
    ):: self.addPanels(
      keyMetrics.headlineMetricsRow(
        runnerServiceType,
        startRow=startRow,
        selectorHash=dashboardFilters.selectorHash,
        showApdex=showApdex,
        showErrorRatio=showErrorRatio,
        showOpsRate=showOpsRate,
        showSaturationCell=showSaturationCell,
        showDashboardListPanel=showDashboardListPanel,
        compact=compact,
        rowHeight=rowHeight,
        rowTitle=null,
      )
    ),
    addRowGrid(
      title,
      startRow,
      panels=[],
    ):: self.addPanels(
      layout.rowGrid(
        title,
        panels,
        startRow=startRow
      )
    ),
    addGrid(
      panels,
      startRow,
      cols=2,
      rowHeight=6,
    ):: self.addPanels(
      layout.grid(
        panels=panels,
        startRow=startRow,
        cols=cols,
        rowHeight=rowHeight,
      )
    ),
    addUnderConstructionNote():: self.addPanels(
      underConstructionNote
    ),
  };

{
  dashboard:: dashboard,
  runnerServiceType:: runnerServiceType,
  runnerServiceDashboardsLinks:: runnerServiceDashboardsLinks,
}
