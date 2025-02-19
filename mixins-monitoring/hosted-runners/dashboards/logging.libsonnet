local mappings = import '../lib/mappings.libsonnet';
local panels = import '../lib/panels.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local basic = import 'runbooks/libsonnet/grafana/basic.libsonnet';
local layout = import 'runbooks/libsonnet/grafana/layout.libsonnet';

local row = grafana.row;

{
  _runnerManagerTemplate:: $._config.templates.runnerManager,

  grafanaDashboards+:: {
    'logging.json':
      basic.dashboard(
        title='%s Logging' % $._config.dashboardName,
        tags=$._config.dashboardTags,
        editable=true,
        includeStandardEnvironmentAnnotations=false,
        includeEnvironmentTemplate=false,
        defaultDatasource=$._config.prometheusDatasource
      ).addTemplate($._runnerManagerTemplate)
      .addPanels(
        panels.headlineMetricsRow(
          serviceType='hosted-runners-logging',
          metricsCatalogServiceInfo=$._config.gitlabMetricsConfig.monitoredServices[1],
          selectorHash={component:"usage_logs"},
          showSaturationCell=false
        )
      )
  }
}
