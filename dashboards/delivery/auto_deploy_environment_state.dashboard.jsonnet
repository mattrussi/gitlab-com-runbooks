local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local row = grafana.row;
local statPanel = grafana.statPanel;


basic.dashboard(
  'Percentage of Auto deploy environment states',
  tags=['release'],
  editable=true,
  time_from='now-1d',
  time_to='now',
)

.addPanel(
  row.new(title='Important environment states'),
  gridPos={ x: 0, y: 0, w: 24, h: 8 },
)

.addPanels(layout.grid([
  statPanel.new(
    'Production awaiting promotion',
    description='Percentage of time of the selected time range that production is ready to accept a new deployment, and there is a package available for promotion.',
    decimals=1,
    unit='percentunit',
    thresholdsMode='percentage',
    reducerFunction='mean',
  )
  .addTarget(
    prometheus.target(
      'sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="gprd", target_stage="main",env_state="awaiting_promotion"})',
      legendFormat=''
    ),
  )
  .addThresholds([
    {
        color: 'red',
        value: null
    },
    {
        color: 'green',
        value: 0
    },
  ]),
  statPanel.new(
    'Staging awaiting promotion',
    description='Percentage of time of the selected time range that staging is ready to accept a new deployment, and there is a package available for promotion.',
    unit='percentunit',
    thresholdsMode='percentage',
  )
  .addTarget(
    prometheus.target(
      'sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="gstg", target_stage="main",env_state="awaiting_promotion"})',
      legendFormat=''
    ),
  )
  .addThresholds([
    {
        color: 'red',
        value: null
    },
    {
        color: 'green',
        value: 0
    },
  ]),
  statPanel.new(
    'Production canary ready to accept new packages',
    description='Percentage of time of the selected time range where production-canary was idle and ready to accept a new deployment.',
    unit='percentunit',
    thresholdsMode='percentage',
  )
  .addTarget(
    prometheus.target(
      'sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="gprd", target_stage="cny",env_state="ready"})',
      legendFormat=''
    ),
  )
  .addThresholds([
    {
        color: 'red',
        value: null
    },
    {
        color: 'green',
        value: 0
    },
  ]),
  statPanel.new(
    'Staging canary ready to accept new packages',
    description='Percentage of time of the selected time range where staging-canary was idle and ready to accept a new deployment.',
    unit='percentunit',
    thresholdsMode='percentage',
  )
  .addTarget(
    prometheus.target(
      'sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="gstg", target_stage="cny",env_state="ready"})',
      legendFormat=''
    ),
  )
  .addThresholds([
    {
        color: 'red',
        value: null
    },
    {
        color: 'green',
        value: 0
    },
  ]),
  statPanel.new(
    'Production canary baking time',
    description='Percentage of time in the selected time range that production canary is baking a package.',
    unit='percentunit',
    thresholdsMode='percentage',
  )
  .addTarget(
    prometheus.target(
      'sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="gprd", target_stage="cny",env_state="baking_time"})',
      legendFormat=''
    ),
  )
  .addThresholds([
    {
        color: 'red',
        value: null
    },
    {
        color: 'green',
        value: 0
    },
  ]),
], cols=2, startRow=100))
.trailer()
