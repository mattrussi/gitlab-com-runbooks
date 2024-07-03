local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;
local promQuery = import 'grafana/prom_query.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local row = grafana.row;
local mimirHelper = import 'services/lib/mimir-helpers.libsonnet';

local explainer = |||
  - Production awaiting promotion - Percentage of time over the selected window where production was idle and waiting for a package to be promoted. This only counts the time where there was a package available for promotion.
  - Staging awaiting promotion - Percentage of time over the selected window where staging was idle and waiting for a package to be promoted. This only counts the time where there was a package available for promotion.
  - Production canary ready to accept new packages - Percentage of time that gprd-cny was idle.
  - Staging canary ready to accept new packages - Percentage of time that gstg-cny was idle.
  - Production canary baking time - Percentage of time where there was a package baking on gprd-cny.
|||;

basic.dashboard(
  'Percentage of Auto deploy environment states',
  tags=['release'],
  editable=true,
  time_from='now-1d',
  time_to='now',
  defaultDatasource=mimirHelper.mimirDatasource('gitlab-ops'),
)

.addPanels(
  layout.singleRow([
    grafana.text.new(
      title='Deployment state explainer',
      mode='markdown',
      content=explainer,
    ),
  ], rowHeight=10, startRow=0)
)

.addPanels(layout.grid([
  basic.statPanel(
    panelTitle='',
    title='Production awaiting promotion',
    description='Percentage of time of the selected time range that production is ready to accept a new deployment, and there is a package available for promotion.',
    decimals=1,
    unit='percentunit',
    thresholdsMode='percentage',
    reducerFunction='mean',
    color='',
    instant=false,
    query='sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="gprd", target_stage="main",env_state="awaiting_promotion"})',
  )
  .addThresholds([
    {
      color: 'red',
      value: null,
    },
    {
      color: 'green',
      value: 0,
    },
  ]),
  basic.statPanel(
    panelTitle='',
    title='Staging awaiting promotion',
    description='Percentage of time of the selected time range that staging is ready to accept a new deployment, and there is a package available for promotion.',
    unit='percentunit',
    thresholdsMode='percentage',
    reducerFunction='mean',
    color='',
    instant=false,
    query='sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="gstg", target_stage="main",env_state="awaiting_promotion"})',
  )
  .addThresholds([
    {
      color: 'red',
      value: null,
    },
    {
      color: 'green',
      value: 0,
    },
  ]),
  basic.statPanel(
    panelTitle='',
    title='Production canary ready to accept new packages',
    description='Percentage of time of the selected time range where production-canary was idle and ready to accept a new deployment.',
    unit='percentunit',
    thresholdsMode='percentage',
    reducerFunction='mean',
    color='',
    instant=false,
    query='sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="gprd", target_stage="cny",env_state="ready"})',
  )
  .addThresholds([
    {
      color: 'red',
      value: null,
    },
    {
      color: 'green',
      value: 0,
    },
  ]),
  basic.statPanel(
    panelTitle='',
    title='Staging canary ready to accept new packages',
    description='Percentage of time of the selected time range where staging-canary was idle and ready to accept a new deployment.',
    unit='percentunit',
    thresholdsMode='percentage',
    reducerFunction='mean',
    color='',
    instant=false,
    query='sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="gstg", target_stage="cny",env_state="ready"})',
  )
  .addThresholds([
    {
      color: 'red',
      value: null,
    },
    {
      color: 'green',
      value: 0,
    },
  ]),
  basic.statPanel(
    panelTitle='',
    title='Production canary baking time',
    description='Percentage of time in the selected time range that production canary is baking a package.',
    unit='percentunit',
    thresholdsMode='percentage',
    reducerFunction='mean',
    color='',
    instant=false,
    query='sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="gprd", target_stage="cny",env_state="baking_time"})',
  )
  .addThresholds([
    {
      color: 'red',
      value: null,
    },
    {
      color: 'green',
      value: 0,
    },
  ]),
], cols=2, startRow=100))
.trailer()
