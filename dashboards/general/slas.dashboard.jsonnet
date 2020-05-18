local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local row = grafana.row;

basic.dashboard(
  'SLAs',
  tags=['general', 'slas', 'service-levels'],
  includeStandardEnvironmentAnnotations=false,
  time_from='now-7d/d',
  time_to='now/d',
)
.addPanel(
  grafana.text.new(
    title='Notice',
    mode='markdown',
    content=|||
      This dashboard has been replaced. Please visit [`https://gitlab.com/gitlab-com/dashboards-gitlab-com/-/environments/1790496/metrics?dashboard=.gitlab%2Fdashboards%2Fsla-dashboard.yml`](https://gitlab.com/gitlab-com/dashboards-gitlab-com/-/environments/1790496/metrics?dashboard=.gitlab%2Fdashboards%2Fsla-dashboard.yml) to see the new location of this dashboard.
    |||
  ),
  gridPos={ x: 0, y: 0, w: 40, h: 2 },
)
