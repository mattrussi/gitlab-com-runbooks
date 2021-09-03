local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';

local diagram = import 'gitlab-dashboards/system_diagram_panel.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

local options = {
  direction: 'LR',
};

basic.dashboard(
  'Overview diagrams',
  tags=[],
  editable=false,
)
.addTemplate(templates.stage)
.addPanels(
  layout.rowGrid(
    'System Diagram (Keyed by Error Rates)',
    startRow=0,
    rowHeight=20,
    collapse=true,
    panels=[
      diagram.errorDiagram(metricsCatalog.services, options),
    ]
  )
)
.addPanels(
  layout.rowGrid(
    'System Diagram (Keyed by Apdex)',
    startRow=20,
    rowHeight=20,
    collapse=true,
    panels=[
      diagram.apdexDiagram(metricsCatalog.services, options),
    ]
  )
)
.addPanels(
  layout.rowGrid(
    'System Diagram (Keyed by Maturity Model)',
    startRow=40,
    rowHeight=20,
    collapse=false,
    panels=[
      diagram.maturityDiagram(metricsCatalog.services, options),
    ]
  )
)
.trailer()
