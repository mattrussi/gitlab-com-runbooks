local capacityPlanning = import 'capacity_planning.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';

basic.dashboard(
  'Service Platform Metrics',
  tags=['general'],
)
.addTemplate(templates.type)
.addTemplate(templates.stage)
.addTemplate(templates.sigma)
.addPanels(
  keyMetrics.headlineMetricsRow(
    '$type',
    3001,
    selectorHash={ env: '$environment', environment: '$environment', type: '$type', stage: '$stage' },
    rowHeight=10
  )
)
.addPanel(
  nodeMetrics.nodeMetricsDetailRow('environment="$environment", stage="$stage", type="$type"'),
  gridPos={
    x: 0,
    y: 5000,
    w: 24,
    h: 1,
  }
)
.addPanel(capacityPlanning.capacityPlanningRow('$type', '$stage'), gridPos={ x: 0, y: 6000 })

+ {
  links+: platformLinks.services + platformLinks.triage,
}
