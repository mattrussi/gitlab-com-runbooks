local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local annotation = grafana.annotation;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;
local templates = import 'grafana/templates.libsonnet';

basic.dashboard(
  'Deployment Health',
  tags=['release'],
  editable=true,
  includeStandardEnvironmentAnnotations=true,
  includeEnvironmentTemplate=true,
)
.addTemplate(templates.stage)

.addPanel(
  row.new(title='Overview'),
  gridPos={ x: 0, y: 0, w: 24, h: 8 },
)
.addPanel(
  graphPanel.new(
    'Deploy Health',
    description='Showcases whether or not an environment and its stage is healthy',
    decimals=0,
    fill=0,
    format='none',
    legend_show=false,
    min=0,
  )
  .addTarget(
    prometheus.target(
      'gitlab_deployment_health:stage{env="$environment", stage="$stage"}'
    ),
  ), gridPos={ x: 0, y: 0, w: 24, h: 10 }
)

.addPanel(
  row.new(title='Service Breakdown'),
  gridPos={ x: 0, y: 0, w: 24, h: 8 },
)
.addPanel(
  graphPanel.new(
    'Service Deployment Health',
    description='Showcases whether or not the environments stage is healthy with a breakdown by the individual services that contribute to the metric',
    decimals=0,
    fill=0,
    legend_current=true,
    legend_alignAsTable=true,
    legend_rightSide=true,
    legend_values=true,
    min=0,
  )
  .addTarget(
    prometheus.target(
      'gitlab_deployment_health:service{env="$environment", stage="$stage"}',
      legendFormat='{{type}}',
    ),
  ), gridPos={ x: 0, y: 100, w: 24, h: 12 }
)

.trailer()
