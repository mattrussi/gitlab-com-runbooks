local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local timepickerlib = import 'github.com/grafana/grafonnet-lib/grafonnet/timepicker.libsonnet';
local prometheus = grafana.prometheus;
local promQuery = import 'grafana/prom_query.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local annotation = grafana.annotation;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;
local row = grafana.row;
local colorScheme = import 'grafana/color_scheme.libsonnet';

local environments = [
  {
    id: 'gprd',
    name: 'Production',
    role: 'gprd',
    stage: 'main',
    icon: '🚀',
  },
  {
    id: 'gprd-cny',
    name: 'Canary',
    role: 'gprd',
    stage: 'cny',
    icon: '🐤',
  },
  {
    id: 'gstg',
    name: 'Staging',
    role: 'gstg',
    stage: 'main',
    icon: '🏗',
  },
  {
    id: 'gstg-cny',
    name: 'Staging Canary',
    role: 'gstg',
    stage: 'cny',
    icon: '🐣',
  },
  {
    id: 'gstg-ref',
    name: 'Staging Ref',
    role: 'gstg-ref',
    stage: 'main',
    icon: '🚧',
  },
];

local annotations = [
  annotation.datasource(
    'Production deploys',
    '-- Grafana --',
    enable=true,
    iconColor='#19730E',
    tags=['deploy', 'gprd'],
  ),
  annotation.datasource(
    'Canary deploys',
    '-- Grafana --',
    enable=false,
    iconColor='#E08400',
    tags=['deploy', 'gprd-cny'],
  ),
  annotation.datasource(
    'Staging deploys',
    '-- Grafana --',
    enable=false,
    iconColor='#5794F2',
    tags=['deploy', 'gstg'],
  ),
  annotation.datasource(
    'Staging Canary deploys',
    '-- Grafana --',
    enable=false,
    iconColor='#8F3BB8',
    tags=['deploy', 'gstg-cny'],
  ),
  annotation.datasource(
    'Staging Ref deploys',
    '-- Grafana --',
    enable=false,
    iconColor='#EB0010',
    tags=['deploy', 'gstg-ref'],
  ),
];

local packageVersion(environment) =
  prometheus.target(
    |||
      topk(1, count(
        omnibus_build_info{environment="%(env)s", stage="%(stage)s", type!~"^redis.*"}
      ) by (version))
    ||| % { env: environment.role, stage: environment.stage },
    instant=true,
    format='table',
    legendFormat='{{version}}',
  );

local environmentPressurePanel(environment) =
  graphPanel.new(
    '%s Auto-deploy pressure' % [environment.icon],
    aliasColors={ Commits: 'semi-dark-purple' },
    decimals=0,
    labelY1='Commits',
    legend_show=false,
    min=0,
  )
  .addTarget(
    prometheus.target(
      'delivery_auto_deploy_pressure{job="delivery-metrics", role="%(role)s"}' % { role: environment.id },
      legendFormat='Commits',
    )
  );

// Stat panel used by top-level Auto-deploy Pressure
local
  deliveryStatPanel(
    title,
    description='',
    query='',
    legendFormat='',
    thresholdsMode='absolute',
    thresholds={},
    links=[]
  ) =
    statPanel.new(
      title,
      description=description,
      allValues=false,
      decimals=0,
      min=0,
      colorMode='value',
      graphMode='area',
      justifyMode='auto',
      orientation='horizontal',
      reducerFunction='lastNotNull',
      thresholdsMode=thresholdsMode,
    )
    .addLinks(links)
    .addThresholds(thresholds)
    .addTarget(
      promQuery.target(
        query,
        legendFormat=legendFormat
      )
    );

// Bar Gauge panel used by top-level Release pressure (based on pick labels)
local bargaugePanel(
  title,
  description='',
  query='',
  legendFormat='',
  thresholds={},
  links=[],
  fieldLinks=[],
  orientation='horizontal',
      ) =
  {
    description: description,
    fieldConfig: {
      values: false,
      defaults: {
        min: 0,
        max: 25,
        thresholds: thresholds,
        links: fieldLinks,
      },
    },
    links: links,
    options: {
      displayMode: 'basic',
      orientation: orientation,
      showUnfilled: true,
    },
    pluginVersion: '7.0.3',
    targets: [promQuery.target(query, legendFormat=legendFormat, instant=true)],
    title: title,
    type: 'bargauge',
  };

basic.dashboard(
  'Release Management',
  tags=['release'],
  editable=true,
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)
.addAnnotations(annotations)

// ----------------------------------------------------------------------------
// Summary
// ----------------------------------------------------------------------------

.addPanel(
  row.new(title='Summary'),
  gridPos={ x: 0, y: 0, w: 24, h: 12 },
)
.addPanels(
  layout.splitColumnGrid([
    // Column 1: package versions
    [
      statPanel.new(
        '%s %s' % [environment.icon, environment.id],
        description='Package running on %s.' % [environment.name],
        reducerFunction='lastNotNull',
        fields='/^version$/',
        colorMode='none',
        graphMode='none',
        textMode='value',
        unit='String',
      )
      .addTarget(packageVersion(environment))
      for environment in environments
    ],
    // Column 2: auto-deploy pressure
    [
      // Auto-build pressure
      deliveryStatPanel(
        'Auto-build pressure',
        description='The number of commits in `master` not yet included in a package.',
        query='max(delivery_auto_build_pressure{project_name=~"omnibus-gitlab-ee|cng-ee|gitlab-ee|gitaly|gitlab_kas"}) by (project_name)',
        legendFormat='{{project_name}}',
        thresholds=[
          { color: colorScheme.normalRangeColor, value: null },
          { color: colorScheme.warningColor, value: 50 },
          { color: colorScheme.errorColor, value: 100 },
          { color: colorScheme.criticalColor, value: 150 },
        ],
        links=[
          {
            targetBlank: true,
            title: 'Latest commits',
            url: 'https://gitlab.com/gitlab-org/gitlab/commits/master',
          },
        ],
      ),
    ],
    // Column 3: auto-deploy pressure
    [
      // Auto-deploy pressure
      deliveryStatPanel(
        'Auto-deploy pressure',
        description='The number of commits in `master` not yet deployed to each environment.',
        query='max(delivery_auto_deploy_pressure{job="delivery-metrics"}) by (role)',
        legendFormat='{{role}}',
        thresholds=[
          { color: colorScheme.normalRangeColor, value: null },
          { color: colorScheme.warningColor, value: 50 },
          { color: colorScheme.errorColor, value: 100 },
          { color: colorScheme.criticalColor, value: 150 },
        ],
        links=[
          {
            targetBlank: true,
            title: 'Latest commits',
            url: 'https://gitlab.com/gitlab-org/gitlab/commits/master',
          },
        ],
      ),
    ],
    // Column 4: S1/S2 Patch release pressure
    [
      bargaugePanel(
        'Patch release pressure: S1/S2',
        description='Number of S1/S2 merge requests merged in previous releases.',
        query=|||
          sum by (version) (delivery_release_pressure{severity=~"severity::1|severity::2",job="delivery-metrics"})
        |||,
        legendFormat='{{version}}',
        thresholds={
          mode: 'absolute',
          steps: [
            { color: colorScheme.normalRangeColor, value: 0 },
            { color: colorScheme.criticalColor, value: 1 },
          ],
        },
      ),
    ],
    // Column 5: Patch release pressure
    [
      bargaugePanel(
        'Patch release pressure: Total ',
        description='Number of merge requests merged in previous releases regardless severity.',
        query=|||
          sum by (version) (delivery_release_pressure{job="delivery-metrics"})
        |||,
        legendFormat='{{version}}',
        thresholds={
          mode: 'absolute',
          steps: [
            { color: colorScheme.normalRangeColor, value: null },
            { color: colorScheme.warningColor, value: 5 },
            { color: colorScheme.errorColor, value: 10 },
            { color: colorScheme.criticalColor, value: 15 },
          ],
        },
      ),
    ],
    // column 6: Post deploy migration pressure
    [
      deliveryStatPanel(
        'Pending migrations',
        description='The number of migrations pending execution in each environment.',
        query='ceil((sum(delivery_metrics_pending_migrations_total{env=~"gstg|gprd",stage="main"}) by (env))/2)',
        legendFormat='{{env}}',
        thresholds=[
          { color: colorScheme.normalRangeColor, value: null },
          { color: colorScheme.warningColor, value: 3 },
          { color: colorScheme.errorColor, value: 4 },
          { color: colorScheme.criticalColor, value: 5 },
        ],
      ),
    ],
  ], cellHeights=[3 for x in environments], startRow=1)
)
.addPanels(
  std.flattenArrays(
    std.mapWithIndex(
      function(index, environment)
        local y = 2000 * (index + 1);
        [
          row.new(
            title='%s %s' % [environment.icon, environment.id]
          )
          { gridPos: { x: 0, y: y, w: 24, h: 12 } },
        ]
        +
        layout.grid(
          [
            environmentPressurePanel(environment),
          ],
          cols=2,
          startRow=y + 2
        ),
      environments
    )
  )
)
.addPanel(
  graphPanel.new(
    'Auto-build pressure',
    decimals=0,
    labelY1='Commits',
    legend_show=false,
    min=0,
  )
  .addTarget(
    prometheus.target(
      'max(delivery_auto_build_pressure{job="delivery-metrics"}) by (project_name)',
      legendFormat='{{project_name}}',
    )
  ), gridPos={ x: 50, y: 2000, w: 12, h: 10 }
)
.trailer()
