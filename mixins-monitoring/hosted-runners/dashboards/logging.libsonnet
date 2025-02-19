local mappings = import '../lib/mappings.libsonnet';
local panels = import '../lib/panels.libsonnet';
local fluentdPanels = import '../lib/fluentd-panels.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local basic = import 'runbooks/libsonnet/grafana/basic.libsonnet';
local layout = import 'runbooks/libsonnet/grafana/layout.libsonnet';

local row = grafana.row;

{
  _runnerManagerTemplate:: $._config.templates.runnerManager,

  _fluentdPluginTemplate:: $._config.templates.fluentdPlugin,

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
      .addTemplate($._fluentdPluginTemplate)
      .addPanels(
        panels.headlineMetricsRow(
          rowTitle='Hosted Runner(s) Logging Overview',
          serviceType='hosted-runners-logging',
          metricsCatalogServiceInfo=$._config.gitlabMetricsConfig.monitoredServices[1],
          selectorHash={component:"usage_logs"},
          showSaturationCell=false
        )
      ).addPanel(
        row.new(title='Fluentd Operations'),
        gridPos={ x: 0, y: 1000, w: 24, h: 1 }
      ).addPanels(layout.grid([
        fluentdPanels.emitRecords($._config.fluentdPluginSelector),
        fluentdPanels.retryWait($._config.fluentdPluginSelector),
        fluentdPanels.writeCounts($._config.fluentdPluginSelector),
        fluentdPanels.errorAndRetryRate($._config.fluentdPluginSelector),
        fluentdPanels.outputFlushTime($._config.fluentdPluginSelector),
        fluentdPanels.bufferLength($._config.fluentdPluginSelector),
        fluentdPanels.bufferTotalSize($._config.fluentdPluginSelector),
        fluentdPanels.bufferFreeSpace($._config.fluentdPluginSelector),
      ], cols=4, rowHeight=8, startRow=1001))
  }
}
