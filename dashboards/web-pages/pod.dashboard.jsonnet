local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local k8sPodsCommon = import 'gitlab-dashboards/kubernetes_pods_common.libsonnet';
local platformLinks = import 'gitlab-dashboards/platform_links.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';

local useTimeSeriesPlugin = true;

basic.dashboard(
  'Pod Info',
  tags=['web-pages'],
)
.addTemplate(templates.gkeCluster)
.addTemplate(templates.stage)
.addTemplate(templates.namespaceGitlab)
.addTemplate(templates.Node)
.addTemplate(
  template.custom(
    name='Deployment',
    query='gitlab-(cny-)?gitlab-pages,',
    current='gitlab-(cny-)?gitlab-pages',
    hide='variable',
  )
)
.addPanel(

  row.new(title='Web Pages Version'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sPodsCommon.version(startRow=1, useTimeSeriesPlugin=useTimeSeriesPlugin))
.addPanel(

  row.new(title='Deployment Info'),
  gridPos={
    x: 0,
    y: 500,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sPodsCommon.deployment(startRow=501))
.addPanels(k8sPodsCommon.status(startRow=502))
.addPanel(

  row.new(title='CPU'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sPodsCommon.cpu(startRow=1001, useTimeSeriesPlugin=useTimeSeriesPlugin))
.addPanel(

  row.new(title='Memory'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sPodsCommon.memory(startRow=2001, container='gitlab-pages', useTimeSeriesPlugin=useTimeSeriesPlugin))
.addPanel(

  row.new(title='Network'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sPodsCommon.network(startRow=3001, useTimeSeriesPlugin=useTimeSeriesPlugin))
+ {
  links+: platformLinks.triage +
          platformLinks.services,
}
