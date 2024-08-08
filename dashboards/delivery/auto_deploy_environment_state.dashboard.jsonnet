local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;
local promQuery = import 'grafana/prom_query.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local mimirHelper = import 'services/lib/mimir-helpers.libsonnet';
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local explainer = |||
  - Awaiting promotion - State where production or staging was idle and waiting for a package to be promoted. This only counts the time where there was a package available for promotion.
  - Ready - State where the environment was idle.
  - Baking time - State where there was a package baking on gprd-cny.
  - Locked - State where there was a deployment ongoing on the environment, or QA, or post-deploy migrations being executed.
|||;

local envStatePieChartPanel(env, stage) =
  g.panel.pieChart.new('%s-%s environment states' % [env, stage])
  + g.panel.pieChart.options.legend.withDisplayMode('table')
  + g.panel.pieChart.options.legend.withShowLegend(true)
  + g.panel.pieChart.options.legend.withValues(['value', 'percent'])
  + g.panel.pieChart.options.withDisplayLabels(['value', 'percent'])
  + g.panel.pieChart.panelOptions.withDescription('Pie chart representation of the percentage of time %s-%s spent in different states' % [env, stage])
  + g.panel.pieChart.options.withReduceOptions({ calcs: ['mean'] })
  + g.panel.pieChart.standardOptions.withUnit('s')
  + g.panel.pieChart.queryOptions.withTargetsMixin([
    g.query.prometheus.new(
      '$PROMETHEUS_DS',
      'sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="%s", target_stage="%s"}) * $__range_s' % [env, stage],
    )
    + g.query.prometheus.withFormat('time_series')
    + g.query.prometheus.withLegendFormat('{{env_state}}'),
  ]);

local envStateGraphPanel(env, stage) =
  graphPanel.new(
    title='%s-%s environment states' % [env, stage],
    description='Time series representation of the percentage of time %s-%s spent in different states' % [env, stage],
    legend_show=true,
    legend_values=true,
    legend_alignAsTable=true,
    legend_current=true,
    legend_max=false,
    legend_min=false,
    legend_avg=false,
    legend_hideEmpty=true,
    legend_hideZero=true,
    decimals=0,
  )
  .addTarget(
    promQuery.target(
      'sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="%s", target_stage="%s"})' % [env, stage],
      legendFormat='{{env_state}}'
    ),
  );

local packageStateBarGaugePanel() =
  g.panel.barGauge.new('Package status when gstg-cny is idle')
  + g.panel.barGauge.panelOptions.withDescription('Amount of time where gstg-cny was idle and packages were in varying states of being built. There can be overlap in the numbers.')
  + g.panel.barGauge.options.withReduceOptions({ calcs: ['mean'] })
  + g.panel.barGauge.standardOptions.withUnit('s')
  + g.panel.barGauge.standardOptions.thresholds.withMode('absolute')
  + g.panel.barGauge.standardOptions.thresholds.withSteps([{ value: null, color: 'green' }])
  + g.panel.barGauge.queryOptions.withTargetsMixin([
    g.query.prometheus.new(
      '$PROMETHEUS_DS',
      '(max by (pkg_state) (delivery_auto_deploy_building_package_state)) * on() group_left max(delivery_auto_deploy_environment_state{target_env="gstg",target_stage="cny",env_state="ready"}) * $__range_s',
    )
    + g.query.prometheus.withFormat('time_series')
    + g.query.prometheus.withLegendFormat('Package build {{pkg_state}}'),

    g.query.prometheus.new(
      '$PROMETHEUS_DS',
      'max(delivery_auto_deploy_environment_state{target_env="gstg",target_stage="cny",env_state="ready"}) * $__range_s',
    )
    + g.query.prometheus.withFormat('time_series')
    + g.query.prometheus.withLegendFormat('gstg-cny idle'),
  ]);

local packageStateGraphPanel() =
  graphPanel.new(
    title='Package build status when gstg-cny is idle',
    description='Time series representation of amount of time where gstg-cny was idle and packages were in varying states of being built.',
    legend_show=true,
    legend_values=true,
    legend_alignAsTable=true,
    legend_current=true,
    legend_max=false,
    legend_min=false,
    legend_avg=false,
    legend_hideEmpty=true,
    legend_hideZero=true,
    decimals=0,
  )
  .addTarget(
    promQuery.target(
      '(max by (pkg_state) (delivery_auto_deploy_building_package_state)) * on() group_left max(delivery_auto_deploy_environment_state{target_env="gstg",target_stage="cny",env_state="ready"})',
      legendFormat='Package build {{pkg_state}}'
    )
  )
  .addTarget(
    promQuery.target(
      'max(delivery_auto_deploy_environment_state{target_env="gstg",target_stage="cny",env_state="ready"})',
      legendFormat='gstg-cny idle'
    ),
  );

basic.dashboard(
  'Percentage of Auto deploy environment states',
  tags=['release'],
  editable=true,
  time_from='now-1d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
  defaultDatasource=mimirHelper.mimirDatasource('gitlab-ops'),
)

.addPanels(
  layout.singleRow([
    grafana.text.new(
      title='Deployment state explainer',
      mode='markdown',
      content=explainer,
    ),
  ], rowHeight=4, startRow=0)
)
.addPanels(layout.grid([
  envStatePieChartPanel('gprd', 'main'),
  envStateGraphPanel('gprd', 'main'),

  envStatePieChartPanel('gprd', 'cny'),
  envStateGraphPanel('gprd', 'cny'),

  envStatePieChartPanel('gstg', 'main'),
  envStateGraphPanel('gstg', 'main'),

  envStatePieChartPanel('gstg', 'cny'),
  envStateGraphPanel('gstg', 'cny'),

  packageStateBarGaugePanel(),
  packageStateGraphPanel(),
], rowHeight=12, cols=2, startRow=100))
.trailer()
