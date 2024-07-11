local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;
local promQuery = import 'grafana/prom_query.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local row = grafana.row;
local mimirHelper = import 'services/lib/mimir-helpers.libsonnet';
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local explainer = |||
  - Awaiting promotion - State where production or staging was idle and waiting for a package to be promoted. This only counts the time where there was a package available for promotion.
  - Ready - State where the environment was idle.
  - Baking time - State where there was a package baking on gprd-cny.
  - Locked - State where there was a deployment ongoing on the environment, or QA, or post-deploy migrations being executed.
|||;

local pieChartPanel(env, stage) =
  g.panel.pieChart.new('%s-%s environment states' % [env, stage])
  + g.panel.pieChart.options.legend.withDisplayMode('table')
  + g.panel.pieChart.options.legend.withShowLegend(true)
  + g.panel.pieChart.options.legend.withValues(['value'])
  + g.panel.pieChart.options.withDisplayLabels(['value'])
  + g.panel.pieChart.panelOptions.withDescription('Pie chart representation of the percentage of time %s-%s spent in different states' % [env, stage])
  + g.panel.pieChart.options.withReduceOptions({ calcs: ['mean'] })
  + g.panel.pieChart.standardOptions.withUnit('percentunit')
  + g.panel.pieChart.queryOptions.withTargetsMixin([
    g.query.prometheus.new(
      '$PROMETHEUS_DS',
      'sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="%s", target_stage="%s"})' % [env, stage],
    )
    + g.query.prometheus.withFormat('time_series')
    + g.query.prometheus.withLegendFormat('{{env_state}}'),
  ]);

local graphPanel(env, stage) =
  basic.graphPanel(
    '%s-%s environment states' % [env, stage],
    description='Time series representation of the percentage of time %s-%s spent in different states' % [env, stage],
    legend_show=true,
    legend_current=true,
    legend_max=false,
    legend_min=false,
    legend_avg=false,
    decimals=0,
  )
  .addTarget(
    promQuery.target(
      'sum without (pod,instance) (delivery_auto_deploy_environment_state{target_env="%s", target_stage="%s"})' % [env, stage],
      legendFormat='{{env_state}}'
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
  pieChartPanel('gprd', 'main'),
  graphPanel('gprd', 'main'),

  pieChartPanel('gprd', 'cny'),
  graphPanel('gprd', 'cny'),

  pieChartPanel('gstg', 'main'),
  graphPanel('gstg', 'main'),

  pieChartPanel('gstg', 'cny'),
  graphPanel('gstg', 'cny'),

], cols=2, startRow=100))
.trailer()
