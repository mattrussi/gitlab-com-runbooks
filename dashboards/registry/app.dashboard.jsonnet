local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local common = import 'gitlab-dashboards/container_common_graphs.libsonnet';
local crCommon = import 'gitlab-dashboards/container_registry_graphs.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';

basic.dashboard(
  'Application Detail',
  tags=['container registry', 'docker', 'registry'],
)
.addTemplate(templates.gkeCluster)
.addTemplate(templates.stage)
.addTemplate(templates.namespaceGitlab)
.addTemplate(
  template.custom(
    'Deployment',
    'gitlab-registry,',
    'gitlab-registry',
    hide='variable',
  )
)
.addPanel(

  row.new(title='Build Info'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(crCommon.version(startRow=1))
.addPanel(

  row.new(title='Stackdriver Metrics'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(common.logMessages(startRow=1001))
.addPanel(

  row.new(title='General Counters'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(common.generalCounters(startRow=2001))
.addPanel(

  row.new(title='Data'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(crCommon.data(startRow=3001))
.addPanel(

  row.new(title='Handler Latencies'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(crCommon.latencies(startRow=4001))
