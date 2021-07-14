local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local prometheus = grafana.prometheus;
local template = grafana.template;
local singlestat = grafana.singlestat;

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
  - __Target SLO__ is the amount of seconds we consider acceptable for a complete deployment from staging to production, it can be one of the following values:
    - `12600`: 3.5h
    - `14400`: 4h
    - `16200`: 4.5h
    - `18000`: 5h
    - `19800`: 5.5h
    - `21600`: 6h
  - __Apdex Score__ shows the percentage of deploymens in the time range that matched the `target SLO`.
  - __Apdex__ shows the Apdex score over time
|||;

basic.dashboard(
  'Deployment SLO',
  tags=['release'],
  editable=true,
  refresh='5m',
  time_from='now-7d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)
.addTemplate(template.new(
  current='19800',
  datasource='Global',
  label='target SLO',
  name='target_slo',
  query='label_values(delivery_deployment_duration_seconds_bucket, le)',
  refresh='load',
  regex='/\\d+/',
  sort=3,  //numerical asc
))


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
.addPanels(layout.singleRow([
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
  singlestat.new(
    'Target SLO',
    valueFontSize='100%',
    format='s',
  ).addTarget(prometheus.target(
    'topk(1, count(delivery_deployment_duration_seconds_bucket{job="delivery-metrics",le="$target_slo"}) by (le))',
    instant=true,
    format='table',
    legendFormat='{{le}}',
  )),
  basic.statPanel(
    title='',
    panelTitle='Apdex score',
    legendFormat='',
    query=sloQuery,
    decimals=1,
    unit='percentunit',
    color=[
      { color: 'red', value: null },
      { color: 'green', value: 95 },
    ]
  ),
], rowHeight=4, startRow=100))

// Apdex SLO
.addPanels(layout.singleRow([
  basic.apdexTimeseries(
    description='Apdex is a measure of deployments that complete within an acceptable threshold duration. Actual threshold can be adjusted using the target SLO variable above in this page. Higher is better.',
    yAxisLabel='% Deploymens w/ Satisfactory duration',
    query=sloQuery
  ),
], rowHeight=10, startRow=200))

.addPanel(
  grafana.row.new(title='⚙️ delivery-metrics service'),
  gridPos={ x: 0, y: 300, w: 24, h: 1 },
).addPanels(layout.singleRow([
  basic.table(
    'PODs',
    description='This table shows the pods running delivery-metrics with their revision and build date, except during a deployment, we expect to see only one pod',
    query='count(delivery_version_info) by (revision, build_date, pod)',
  ),
], rowHeight=4, startRow=300))


.trailer()
