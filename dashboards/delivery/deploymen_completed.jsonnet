local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;

basic.dashboard(
  'delivery-metrics deployment status',
  tags=[],
  editable=true,
  time_from='now-2d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)

.addPanel(
  graphPanel.new(
    '🥺 the increase of failed deployment',
    description='The increased value of failed deployments',
    decimals=0,
    format='none',
    legend_current=true,
    legend_alignAsTable=true,
    legend_values=true,
    min=0,
  )
  .addTarget(
    prometheus.target(
      'sum(increase(delivery_deployment_started_total{target_env!="gstg-ref"}[1d])) by (target_env) - sum(increase(delivery_deployment_completed_total{target_env!="gstg-ref"}[1d])) by (target_env)',
      legendFormat='{{target_env}}',
    ),
  ), gridPos={ x: 0, y: 200, w: 24, h: 12 }
)

.addPanel(
  graphPanel.new(
    '🚀 Number of deployments completed',
    description='Number of deployments completed per day.',
    decimals=0,
    format='none',
    legend_current=true,
    legend_alignAsTable=true,
    legend_values=true,
    min=0,
  )
  .addTarget(
    prometheus.target(
      'sum(increase(delivery_deployment_completed_total{target_env!="gstg-ref"}[1d])) by (target_env)',
      legendFormat='{{target_env}}',
    ),
  ), gridPos={ x: 0, y: 200, w: 24, h: 12 }
)

.addPanel(
  graphPanel.new(
    '🚀 Number of deployments started',
    description='Number of deployments started per day.',
    decimals=0,
    format='none',
    legend_current=true,
    legend_alignAsTable=true,
    legend_values=true,
    min=0,
  )
  .addTarget(
    prometheus.target(
      'sum(increase(delivery_deployment_started_total{target_env!="gstg-ref"}[1d])) by (target_env)',
      legendFormat='{{target_env}}',
    ),
  ), gridPos={ x: 0, y: 200, w: 24, h: 12 }
)


.trailer()
