local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local annotation = grafana.annotation;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local statPanel = grafana.statPanel;

local annotations = [
  annotation.datasource(
    'Production deploys',
    '-- Grafana --',
    enable=false,
    iconColor='#19730E',
    tags=['deploy', 'gprd'],
  ),
  annotation.datasource(
    'Canary deploys',
    '-- Grafana --',
    enable=false,
    iconColor='#E08400',
    tags=['deploy', 'gprd-cny'],
  ),
  annotation.datasource(
    'Staging deploys',
    '-- Grafana --',
    enable=false,
    iconColor='#5794F2',
    tags=['deploy', 'gstg'],
  ),
  annotation.datasource(
    'Staging Canary deploys',
    '-- Grafana --',
    enable=false,
    iconColor='#8F3BB8',
    tags=['deploy', 'gstg-cny'],
  ),
];

basic.dashboard(
  'Auto-Deploy packages information',
  tags=['release'],
  editable=true,
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
  time_from='now-14d'
)
.addAnnotations(annotations)

.addPanel(
  graphPanel.new(
    '📦 Number of packages tagged per day',
    description='Number of packages tagged per day.',
    decimals=0,
    format='none',
    legend_current=true,
    legend_alignAsTable=true,
    legend_values=true,
    min=0,
  )
  .addTarget(
    prometheus.target(
      'sum(increase(delivery_packages_tagging_total{pkg_type="auto_deploy"}[1d])) by (pkg_type)',
      legendFormat='Tagged packages',
    ),
  )
  .addTarget(
    prometheus.target(
      |||
        clamp_min(
          sum(increase(delivery_packages_tagging_total{pkg_type="auto_deploy"}[1d])) -
          sum(increase(delivery_deployment_started_total{target_env="gprd"}[1d]))
        , 0)
      |||, legendFormat='Not promoted'
    )
  ), gridPos={ x: 0, y: 0, w: 24, h: 10 }
)
.addPanel(
  graphPanel.new(
    '🚀 Number of deployments started per day',
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
  ), gridPos={ x: 0, y: 10, w: 24, h: 12 }
)
