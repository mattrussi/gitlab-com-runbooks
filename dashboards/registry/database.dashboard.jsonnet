local crCommon = import 'container_registry_graphs.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';

basic.dashboard(
  'Database Info',
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
  row.new(title='Connection Pool'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(crCommon.dbConnPool(startRow=1))
