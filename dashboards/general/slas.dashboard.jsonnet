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
  row.new(title='Headline'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanel(
  grafana.text.new(
    title='Notice',
    mode='markdown',
    content=|||
      This dashboard has been replaced. Please visit [`general-public-splashscreen`](d/general-public-splashscreen) to see the new location of this dashboard.
    |||
  ),
  gridPos={ x: 8, y: 0, w: 16, h: 8 },
)
