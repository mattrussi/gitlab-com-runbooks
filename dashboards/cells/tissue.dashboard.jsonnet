local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local mimirHelper = import 'services/lib/mimir-helpers.libsonnet';
local colorScheme = import 'grafana/color_scheme.libsonnet';

local text = grafana.text;
local template = grafana.template;

basic.dashboard(
  'Tissue - Ring Deployments',
  tags=['delivery'],
  includeEnvironmentTemplate=false,
  includeStandardEnvironmentAnnotations=false,
  defaultDatasource=mimirHelper.mimirDatasource('gitlab-ops'),
)

.addTemplate(
  template.new(
    'amp_environment',
    '$PROMETHEUS_DS',
    'label_values(delivery_tissue_patches_queued_current,amp)',
    current='cellsdev',
    refresh='load',
    sort=1,
  )
)

.addPanel(
  text.new(
    title='Cells Deployments Dashboard',
    mode='markdown',
    content=|||
      GitLab Cells deployments are managed by 🧫 Tissue.

      [List of deployment pipelines](https://ops.gitlab.net/gitlab-com/gl-infra/cells/tissue/-/pipelines?scope=all&source=api).
    |||
  ),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 3,
  },
)

.addPanels(layout.grid([
  basic.statPanel(
    panelTitle="In rollout patches",
    title="",
    color=[
      { color: colorScheme.warningColor, value: null },
      { color: colorScheme.normalRangeColor, value: 1 },
    ],
    query=|||
      sum(last_over_time(delivery_tissue_patches_queued_current{amp="$amp_environment",patch_status="in rollout"}[$__rate_interval])) by (ring)
    |||,
    legendFormat='Ring {{ring}}',
    description='this is my description',
    unit='',
    decimals=0,
    min=0,
    max=1,
    instant=true,
    interval='1m',
    intervalFactor=1,
    allValues=false,
    reducerFunction='lastNotNull',
    fields='',
    mappings=[],
    colorMode='background',
    graphMode='area',
    justifyMode='auto',
    textMode='auto',
    thresholdsMode='absolute',
    orientation='vertical',
    noValue=null,
    links=[],
  ),
  basic.statPanel(
    panelTitle="Failed patches",
    title="",
    color=[
      { color: colorScheme.normalRangeColor, value: null },
      { color: colorScheme.criticalColor, value: 1 },
    ],
    query=|||
      sum(last_over_time(delivery_tissue_patches_queued_current{amp="$amp_environment",patch_status="failed"}[$__rate_interval])) by (ring)
    |||,
    legendFormat='Ring {{ring}}',
    description='this is my description',
    unit='',
    decimals=0,
    min=0,
    max=1,
    instant=true,
    interval='1m',
    intervalFactor=1,
    allValues=false,
    reducerFunction='lastNotNull',
    fields='',
    mappings=[],
    colorMode='background',
    graphMode='area',
    justifyMode='auto',
    textMode='auto',
    thresholdsMode='absolute',
    orientation='vertical',
    noValue=null,
    links=[],
  ),
], cols=2, rowHeight=6))

.trailer()

