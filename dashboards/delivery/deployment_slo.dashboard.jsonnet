local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local mimirHelper = import 'services/lib/mimir-helpers.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';

local useTimeSeriesPlugin = true;

local sloQuery = |||
  sum(rate(delivery_deployment_duration_seconds_bucket{job="delivery-metrics",status="success",le="$target_slo"}[$__range]))
  /
  sum(rate(delivery_deployment_duration_seconds_count{job="delivery-metrics",status="success"}[$__range]))
|||;
local numberOfDeploymentQuery = 'sum(increase(delivery_deployment_duration_seconds_count{job="delivery-metrics",status="success"}[$__range]))';

local explainer = |||
  This dashboard shows a summary of deployments on gitlab.com.

  This section of the dashboard is governed by the `target SLO` variable.

  - __# deployments__ counts the number of deployments in the time range`
  - __Target SLO__ is the amount of seconds we consider acceptable for a complete deployment from gstg-cny (staging canary) to production (gprd), it can be one of the following values:
    - `12600`: 3.5h
    - `14400`: 4h
    - `16200`: 4.5h
    - `18000`: 5h
    - `19800`: 5.5h
    - `21600`: 6h
    - `23400`: 6.5h
    - `25200`: 7h
    - `27000`: 7.5h
    - `28800`: 8h
    - `30600`: 8.5h
    - `32400`: 9h
    - `34200`: 9.5
    - `36000`: 10h
  - __Apdex Score__ shows the percentage of deploymens in the time range that matched the `target SLO`.
  - __Apdex__ shows the Apdex score over time
|||;

local pipeline_duration_query_per_day = |||
  quantile(%(quantile)s,
    last_over_time(delivery_deployment_pipeline_duration_seconds{pipeline_name="%(pipeline_name)s",project_name="%(project)s"}[1d])
      unless
    last_over_time(delivery_deployment_pipeline_duration_seconds{pipeline_name="%(pipeline_name)s",project_name="%(project)s"}[1h] offset 1d)
  )
|||;

local pipeline_duration_query_per_week = |||
  quantile(%(quantile)s,
    last_over_time(delivery_deployment_pipeline_duration_seconds{pipeline_name="%(pipeline_name)s",project_name="%(project)s"}[1w])
      unless
    last_over_time(delivery_deployment_pipeline_duration_seconds{pipeline_name="%(pipeline_name)s",project_name="%(project)s"}[1h] offset 1w)
  )
|||;

basic.dashboard(
  'Deployment SLO',
  tags=['release'],
  editable=true,
  time_from='now-30d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
  defaultDatasource=mimirHelper.mimirDatasource('gitlab-ops'),
)
.addTemplate(template.new(
  current='28800',
  label='target SLO',
  name='target_slo',
  query='label_values(delivery_deployment_duration_seconds_bucket, le)',
  datasource=mimirHelper.mimirDatasource('gitlab-ops'),
  refresh='load',
  regex='/\\d+/',
  sort=3,  //numerical asc
))

.addPanel(
  grafana.row.new(title='Deployment SLO'),
  gridPos={
    x: 0,
    y: 0,
    w: 12,
    h: 24,
  }
)

.addPanels(
  layout.singleRow([
    grafana.text.new(
      title='Deployment SLO Explainer',
      mode='markdown',
      content=explainer,
    ),
  ], rowHeight=10, startRow=0)
)

// Number of deployments
.addPanels(layout.grid([
  basic.statPanel(
    title='',
    panelTitle='# deployments',
    colorMode='value',
    legendFormat='',
    query=numberOfDeploymentQuery,
    color=[
      { color: 'red', value: null },
      { color: 'green', value: 1 },
    ]
  ),
  basic.statPanel(
    '',
    'Target SLO',
    color='',
    query='topk(1, count(delivery_deployment_duration_seconds_bucket{job="delivery-metrics",le="$target_slo"}) by (le))',
    instant=false,
    legendFormat='{{le}}',
    format='table',
    unit='s',
    fields='/^le$/',
    colorMode='none',
    textMode='value',
  ),
  basic.statPanel(
    title='',
    panelTitle='Apdex score',
    legendFormat='',
    query=sloQuery,
    decimals=1,
    unit='percentunit',
    color=[
      { color: 'red', value: null },
      { color: 'yellow', value: 0.5 },
      { color: 'green', value: 0.95 },
    ]
  ),
], cols=3, rowHeight=4, startRow=100))

.addPanels(
  layout.grid(
    if useTimeSeriesPlugin then
      [
        // Deployment duration over time
        panel.basic(
          'Deployment duration',
          unit='clocks',
        )
        .addYaxis(
          label='Duration',
        )
        .addTarget(
          prometheus.target('max(delivery_deployment_duration_last_seconds) by (deployment_type, status)', legendFormat='Duration')
        ),
        // Apdex
        panel.apdexTimeSeries(
          description='Apdex is a measure of deployments that complete within an acceptable threshold duration. Actual threshold can be adjusted using the target SLO variable above in this page. Higher is better.',
          yAxisLabel='% Deployments w/ satisfactory duration',
          query=sloQuery
        ),
      ]
    else
      [
        // Deployment duration over time
        graphPanel.new(
          'Deployment duration',
          decimals=1,
          labelY1='Duration',
          formatY1='clocks',

          legend_values=true,
          legend_max=true,
          legend_min=true,
          legend_avg=true,
          legend_current=true,
          legend_alignAsTable=true,
        )
        .addTarget(
          prometheus.target('max(delivery_deployment_duration_last_seconds) by (deployment_type, status)', legendFormat='Duration')
        ),

        // Apdex
        basic.apdexTimeseries(
          description='Apdex is a measure of deployments that complete within an acceptable threshold duration. Actual threshold can be adjusted using the target SLO variable above in this page. Higher is better.',
          yAxisLabel='% Deployments w/ satisfactory duration',
          query=sloQuery
        ),
      ], startRow=200,
  ),
)

.addPanels(
  layout.grid(
    if useTimeSeriesPlugin then
      [
        grafana.row.new(title='Packager pipeline duration'),
        panel.basic(
          'Duration of Omnibus packager pipelines',
          description='Time taken for 80% of Omnibus packager pipelines to complete',
          unit='short',
        )
        .addYaxis(
          min=0,
          label='Duration',
        )
        .addTarget(
          prometheus.target(
            pipeline_duration_query_per_day % { quantile: '0.8', pipeline_name: 'AUTO_DEPLOY_BUILD_PIPELINE', project: 'gitlab/omnibus-gitlab' },
            legendFormat='Omnibus P80 duration per day',
          )
        )
        .addTarget(
          prometheus.target(
            pipeline_duration_query_per_week % { quantile: '0.8', pipeline_name: 'AUTO_DEPLOY_BUILD_PIPELINE', project: 'gitlab/omnibus-gitlab' },
            legendFormat='Omnibus P80 duration per week',
          )
        ),
        panel.basic(
          'Duration of CNG packager pipelines',
          description='Time taken for 80% of CNG packager pipelines to complete',
          unit='short',
        )
        .addYaxis(
          min=0,
          label='Duration',
        )
        .addTarget(
          prometheus.target(
            pipeline_duration_query_per_day % { quantile: '0.8', pipeline_name: 'AUTO_DEPLOY_BUILD_PIPELINE', project: 'gitlab/charts/components/images' },
            legendFormat='CNG P80 duration per day',
          )
        )
        .addTarget(
          prometheus.target(
            pipeline_duration_query_per_week % { quantile: '0.8', pipeline_name: 'AUTO_DEPLOY_BUILD_PIPELINE', project: 'gitlab/charts/components/images' },
            legendFormat='CNG P80 duration per week',
          )
        ),
      ]
    else
      [
        grafana.row.new(title='Packager pipeline duration'),

        graphPanel.new(
          'Duration of Omnibus packager pipelines',
          description='Time taken for 80% of Omnibus packager pipelines to complete',
          decimals=2,
          labelY1='Duration',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          min=0,
          format='s',
        )
        .addTarget(
          prometheus.target(
            pipeline_duration_query_per_day % { quantile: '0.8', pipeline_name: 'AUTO_DEPLOY_BUILD_PIPELINE', project: 'gitlab/omnibus-gitlab' },
            legendFormat='Omnibus P80 duration per day',
          )
        )
        .addTarget(
          prometheus.target(
            pipeline_duration_query_per_week % { quantile: '0.8', pipeline_name: 'AUTO_DEPLOY_BUILD_PIPELINE', project: 'gitlab/omnibus-gitlab' },
            legendFormat='Omnibus P80 duration per week',
          )
        ),

        graphPanel.new(
          'Duration of CNG packager pipelines',
          description='Time taken for 80% of CNG packager pipelines to complete',
          decimals=2,
          labelY1='Duration',
          legend_values=true,
          legend_current=true,
          legend_alignAsTable=true,
          min=0,
          format='s',
        )
        .addTarget(
          prometheus.target(
            pipeline_duration_query_per_day % { quantile: '0.8', pipeline_name: 'AUTO_DEPLOY_BUILD_PIPELINE', project: 'gitlab/charts/components/images' },
            legendFormat='CNG P80 duration per day',
          )
        )
        .addTarget(
          prometheus.target(
            pipeline_duration_query_per_week % { quantile: '0.8', pipeline_name: 'AUTO_DEPLOY_BUILD_PIPELINE', project: 'gitlab/charts/components/images' },
            legendFormat='CNG P80 duration per week',
          )
        ),
      ], cols=2, rowHeight=10, startRow=300
  )
)
.trailer()
