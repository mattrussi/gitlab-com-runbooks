local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local services = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local keyMetrics = import 'gitlab-dashboards/key_metrics.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local row = grafana.row;
local text = grafana.text;

local selector = {};

basic.dashboard(
  'Triage',
  tags=['general']
)
.addPanel(
  row.new(title='SERVICES'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(keyMetrics.headlineMetricsRow('webservice', startRow=1100, rowTitle='Web Service', selectorHash=selector, stableIdPrefix='web', showDashboardListPanel=true))
.addPanels(keyMetrics.headlineMetricsRow('gitaly', startRow=1200, rowTitle='Gitaly', selectorHash=selector, stableIdPrefix='api', showDashboardListPanel=true))
.trailer()
{
  uid: 'triage',
}
