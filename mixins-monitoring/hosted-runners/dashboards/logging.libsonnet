local grafana = import 'grafonnet/grafana.libsonnet';
local basic = import 'runbooks/libsonnet/grafana/basic.libsonnet';
local layout = import 'runbooks/libsonnet/grafana/layout.libsonnet';

local runnerPanels = import './panels/runner.libsonnet';
local fluentdPanels = import './panels/fluentd.libsonnet';
local replicationPanels = import './panels/replications.libsonnet';

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
        runnerPanels.headlineMetricsRow(
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
      .addPanel(
        row.new(title='Replication Metrics'),
        gridPos={ x: 0, y: 2000, w: 24, h: 1 }
      ).addPanels(layout.grid([
        replicationPanels.pendingOperations($._config.replicationSelector),
        replicationPanels.latency($._config.replicationSelector),
        replicationPanels.bytesPending($._config.replicationSelector),
        replicationPanels.operationsFailed($._config.replicationSelector),
      ], cols=4, rowHeight=8, startRow=2001))
  }
}
