local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local templates = import 'grafana/templates.libsonnet';
local template = grafana.template;
local promQuery = import 'grafana/prom_query.libsonnet';
local colorScheme = import 'grafana/color_scheme.libsonnet';
local row = grafana.row;

local explainer = |||
  This dashboard shows information about each particular deployment.

|||;

local bargaugePanel(
  title,
  description='',
  query='',
  legendFormat='',
  thresholds={},
  links=[],
  fieldLinks=[],
  orientation='vertical',
      ) =
  {
    description: description,
    fieldConfig: {
      values: false,
      defaults: {
        reduceOptions: {
          calcs: [
            'last',
          ],
        },
        thresholds: thresholds,
        unit: 's',
        links: fieldLinks,
        mode: 'thresholds',
      },
    },
    links: links,
    options: {
      displayMode: 'basic',
      orientation: orientation,
      showUnfilled: true,
    },
    pluginVersion: '9.3.6',
    targets: [promQuery.target(query, legendFormat=legendFormat, instant=true)],
    title: title,
    type: 'bargauge',
  };


basic.dashboard(
  'deployment-metrics',
  tags=[],
  editable=true,
  time_from='now-1d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)

.addTemplate(
  template.new(
    'environment',
    '$PROMETHEUS_DS',
    'label_values(delivery_deployment_merge_request_lead_time_seconds, target_env)',
    label='environment',
    refresh='time',
  )
)

.addTemplate(
  template.new(
    'target_stage',
    '$PROMETHEUS_DS',
    'label_values(delivery_deployment_merge_request_lead_time_seconds{target_env="$environment"}, target_stage)',
    label='stage',
    refresh='time',
  )
)

.addTemplate(
  template.new(
    'deploy_version',
    '$PROMETHEUS_DS',
    'label_values(delivery_deployment_merge_request_lead_time_seconds{target_env="$environment", target_stage="$target_stage"}, deploy_version)',
    label='version',
    refresh='time',
    sort=2,
  )
)
.addPanel(
  row.new(title='📊 Merge requests statistics'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.columnGrid([
    [
      bargaugePanel(
        'Merge requests lead time',
        description='Time it take Merge Request from being merged to production',
        query='last_over_time(delivery_deployment_merge_request_lead_time_seconds{target_env="$environment", target_stage="$target_stage", deploy_version="$deploy_version"}[$__range])',
        legendFormat='{{mr_id}}',
        fieldLinks=[
          {
            title: 'View merge request',
            url: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/${__field.labels.mr_id}',
            targetBlank: true,
          },
        ],
        thresholds={
          steps: [
            { color: colorScheme.normalRangeColor, value: 0 },
            { color: colorScheme.warningColor, value: 39600 },
            { color: colorScheme.errorColor, value: 43200 },
            { color: colorScheme.criticalColor, value: 46800 },
          ],
        },
      ),
      basic.statPanel(
        title='',
        panelTitle='Average MR lead time',
        color='blue',
        query='avg(last_over_time(delivery_deployment_merge_request_lead_time_seconds{target_env="$environment", target_stage="$target_stage", deploy_version="$deploy_version"}[$__range]))',
        legendFormat='__auto',
        colorMode='background',
        textMode='value',
        unit='s',
      )
      .addThresholds([
        { color: colorScheme.normalRangeColor, value: 0 },
        { color: colorScheme.warningColor, value: 39600 },
        { color: colorScheme.errorColor, value: 43200 },
        { color: colorScheme.criticalColor, value: 46800 },
      ]),
    ],
  ], [19, 5], rowHeight=10, startRow=1)
)

.trailer()
