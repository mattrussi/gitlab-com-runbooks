local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local stages = (import 'service-catalog/stages.libsonnet');
local template = grafana.template;
local prebuiltTemplates = import 'grafana/templates.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local platformLinks = import 'gitlab-dashboards/platform_links.libsonnet';
local errorBudget = import 'stage-groups/error_budget.libsonnet';
local sidekiqHelpers = import 'services/lib/sidekiq-helpers.libsonnet';
local thresholds = import 'gitlab-dashboards/thresholds.libsonnet';
local metricsCatalogDashboards = import 'gitlab-dashboards/metrics_catalog_dashboards.libsonnet';
local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local keyMetrics = import 'gitlab-dashboards/key_metrics.libsonnet';

local actionLegend(type) =
  if type == 'api' then '{{action}}' else '{{controller}}#{{action}}';

local controllerFilter(featureCategoriesSelector) =
  template.new(
    'controller',
    '$PROMETHEUS_DS',
    "label_values(controller_action:gitlab_transaction_duration_seconds_count:rate1m{environment='$environment', feature_category=~'(%s)'}, controller)" % featureCategoriesSelector,
    current=null,
    refresh='load',
    sort=1,
    includeAll=true,
    allValues='.*',
    multi=true,
  );

local actionFilter(featureCategoriesSelector) =
  template.new(
    'action',
    '$PROMETHEUS_DS',
    "label_values(controller_action:gitlab_transaction_duration_seconds_count:rate1m{environment='$environment', controller=~'$controller', feature_category=~'(%s)'}, action)" % featureCategoriesSelector,
    current=null,
    refresh='load',
    sort=1,
    multi=true,
    includeAll=true,
    allValues='.*'
  );

local groupFilter(hide=false, current='project_management') =
  template.new(
    'stage_group',
    '$PROMETHEUS_DS',
    "label_values(gitlab:feature_category:stage_group:mapping{monitor='global'}, stage_group)",
    current='project_management',
    refresh='load',
    sort=1,
    includeAll=true,
    allValues='.*',
    multi=false,
    hide=if hide then 'hidden' else '',
  );

local errorBudgetPanels(group) =
  [
    [
      errorBudget.panels.availabilityStatPanel(group.key),
      errorBudget.panels.availabilityTargetStatPanel(group.key),
    ],
    [
      errorBudget.panels.timeRemainingStatPanel(group.key),
      errorBudget.panels.timeRemainingTargetStatPanel(group.key),
    ],
    [
      errorBudget.panels.timeSpentStatPanel(group.key),
      errorBudget.panels.timeSpentTargetStatPanel(group.key),
    ],
    [
      errorBudget.panels.explanationPanel(group.name),
    ],
  ];

local errorBudgetAttribution(group, featureCategories) =
  [
    errorBudget.panels.violationRatePanel(group.key),
    errorBudget.panels.violationRateExplanation,
    errorBudget.panels.logLinks(featureCategories),
  ];

local railsRequestRate(type, featureCategories, featureCategoriesSelector) =
  basic.timeseries(
    title='%(type)s Request Rate' % { type: std.asciiUpper(type) },
    yAxisLabel='Requests per Second',
    legendFormat=actionLegend(type),
    decimals=2,
    query=|||
      sum by (controller, action) (
        rate(gitlab_transaction_duration_seconds_count{
          environment='$environment',
          stage='$stage',
          feature_category=~'(%(featureCategories)s)',
          type='%(type)s',
          controller=~'$controller',
          action=~'$action'
        }[$__interval])
      )
    ||| % {
      type: type,
      featureCategories: featureCategoriesSelector,
    }
  );

local railsErrorRate(type, featureCategories, featureCategoriesSelector) =
  basic.timeseries(
    title='%(type)s Error Rate' % { type: std.asciiUpper(type) },
    decimals=2,
    legendFormat='%s error rate' % type,
    yAxisLabel='Requests per Second',
    query=|||
      sum by (component) (
        gitlab:component:feature_category:execution:error:rate_5m{
          environment='$environment',
          stage='$stage',
          feature_category=~'(%(featureCategories)s)',
          type='%(type)s'
        }
      )
    ||| % {
      type: type,
      featureCategories: featureCategoriesSelector,
    }
  );

local railsP95RequestLatency(type, featureCategories, featureCategoriesSelector) =
  basic.timeseries(
    title='%(type)s 95th Percentile Request Latency' % { type: std.asciiUpper(type) },
    decimals=2,
    format='s',
    legendFormat=actionLegend(type),
    query=|||
      avg(
        avg_over_time(
          controller_action:gitlab_transaction_duration_seconds:p95{
            environment="$environment",
            stage='$stage',
            action=~"$action",
            controller=~"$controller",
            feature_category=~'(%(featureCategories)s)',
            type='%(type)s'
          }[$__interval]
        )
      ) by (controller, action)
    ||| % {
      type: type,
      featureCategories: featureCategoriesSelector,
    }
  );

local sqlQueriesPerAction(type, featureCategories, featureCategoriesSelector) =
  basic.timeseries(
    title='%(type)s SQL Queries per Action' % { type: std.asciiUpper(type) },
    decimals=2,
    yAxisLabel='Queries',
    legendFormat=actionLegend(type),
    description=|||
      Average amount of SQL queries performed by a controller action.
    |||,
    query=|||
      sum by (controller, action) (
        controller_action:gitlab_sql_duration_seconds_count:rate1m{
          environment="$environment",
          stage='$stage',
          action=~"$action",
          controller=~"$controller",
          feature_category=~'(%(featureCategories)s)',
          type='%(type)s'
        }
      )
      /
      sum by (controller, action) (
        controller_action:gitlab_transaction_duration_seconds_count:rate1m{
          environment="$environment",
          stage='$stage',
          action=~"$action",
          controller=~"$controller",
          feature_category=~'(%(featureCategories)s)',
          type='%(type)s'
        }
      )
    ||| % {
      type: type,
      featureCategories: featureCategoriesSelector,
    }
  );

local sqlLatenciesPerAction(type, featureCategories, featureCategoriesSelector) =
  basic.timeseries(
    title='%(type)s SQL Latency per Action' % { type: std.asciiUpper(type) },
    decimals=2,
    format='s',
    legendFormat=actionLegend(type),
    description=|||
      Average sum of all SQL query latency accumulated by a controller action.
    |||,
    query=|||
      avg_over_time(
        controller_action:gitlab_sql_duration_seconds_sum:rate1m{
          environment="$environment",
          stage='$stage',
          action=~"$action",
          controller=~"$controller",
          feature_category=~'(%(featureCategories)s)',
          type='%(type)s'
        }[$__interval]
      )
      /
      avg_over_time(
        controller_action:gitlab_transaction_duration_seconds_count:rate1m{
          environment="$environment",
          stage='$stage',
          action=~"$action",
          controller=~"$controller",
          feature_category=~'(%(featureCategories)s)',
          type='%(type)s'
        }[$__interval]
      )
    ||| % {
      type: type,
      featureCategories: featureCategoriesSelector,
    }
  );

local sqlLatenciesPerQuery(type, featureCategories, featureCategoriesSelector) =
  basic.timeseries(
    title='%(type)s SQL Latency per Query' % { type: std.asciiUpper(type) },
    decimals=2,
    legendFormat=actionLegend(type),
    format='s',
    description=|||
      Average latency of individual SQL queries
    |||,
    query=|||
      sum by (controller, action) (
        rate(
          gitlab_sql_duration_seconds_sum{
            environment="$environment",
            stage='$stage',
            action=~"$action",
            controller=~"$controller",
            feature_category=~'(%(featureCategories)s)',
            type='%(type)s'
          }[$__interval]
        )
      )
      /
      sum by (controller, action) (
        rate(
          gitlab_sql_duration_seconds_count{
            environment="$environment",
            stage='$stage',
            action=~"$action",
            controller=~"$controller",
            feature_category=~'(%(featureCategories)s)',
            type='%(type)s'
          }[$__interval]
        )
      )
    ||| % {
      type: type,
      featureCategories: featureCategoriesSelector,
    }
  );

local cachesPerAction(type, featureCategories, featureCategoriesSelector) =
  basic.timeseries(
    title='%(type)s Caches per Action' % { type: std.asciiUpper(type) },
    decimals=2,
    legendFormat='{{operation}} - %s' % actionLegend(type),
    yAxisLabel='Operations',
    description=|||
      Average total number of caching operations (Read & Write) per action.
    |||,
    query=|||
      sum by (controller, action, operation) (
        rate(
          gitlab_cache_operations_total{
            environment="$environment",
            stage='$stage',
            action=~"$action",
            controller=~"$controller",
            feature_category=~'(%(featureCategories)s)',
            type='%(type)s'
          }[$__interval]
        )
      )
    ||| % {
      type: type,
      featureCategories: featureCategoriesSelector,
    }
  );

local sidekiqJobRate(counter, title, description, featureCategoriesSelector) =
  basic.timeseries(
    title=title,
    description=description,
    decimals=2,
    yAxisLabel='Jobs per Second',
    legendFormat='{{worker]}}',
    query=|||
      sum by (worker) (
        rate(%(counter)s{
          environment="$environment",
          stage='$stage',
          feature_category=~'(%(featureCategories)s)'
        }[$__interval])
      )
    ||| % {
      counter: counter,
      featureCategories: featureCategoriesSelector,
    }
  );

local sidekiqJobDurationP95(featureCategories, urgency, threshold) =
  basic.timeseries(
    title='%s urgency jobs' % urgency,
    description='%(urgency)s urgency jobs (%(threshold)i seconds max duration)' % {
      urgency: urgency,
      threshold: threshold,
    },
    decimals=2,
    yAxisLabel='Job Duration seconds',
    legendFormat='{{ worker }}',
    thresholds=[thresholds.errorLevel('gt', threshold)],
    query=|||
      histogram_quantile(0.95,
        sum by (worker, le) (
          rate(
            sidekiq_jobs_completion_seconds_bucket{
              environment="$environment",
              stage='$stage',
              feature_category=~'(%(featureCategories)s)',
              urgency='%(urgency)s'
            }[$__interval]
          )
        )
      )
    ||| % {
      featureCategories: featureCategories,
      urgency: urgency,
    }
  );

local sidekiqJobDurationByUrgency(urgencies, featureCategoriesSelector) =
  // mapping an urgency to the slo key in `services/lib/sidekiq-helpers.libsonnet`
  local urgencySLOMapping = {
    high: 'urgent',
    low: 'lowUrgency',
    throttled: 'throttled',
  };
  local unknownUrgencies = std.setDiff(urgencies, std.objectFields(urgencySLOMapping));
  assert std.length(unknownUrgencies) == 0 :
         'Unknown urgency %s' % unknownUrgencies;
  local slos = sidekiqHelpers.slos;

  layout.rowGrid(
    'Sidekiq job duration',
    [
      sidekiqJobDurationP95(featureCategoriesSelector, urgency, slos[urgencySLOMapping[urgency]].executionDurationSeconds)
      for urgency in urgencies
    ],
    // Just after the sidekiq panels
    startRow=950,
  );

local requestComponents = std.set(['web', 'api', 'git']);
local backgroundComponents = std.set(['sidekiq']);
local supportedComponents = std.setUnion(requestComponents, backgroundComponents);
local defaultComponents = std.set(['web', 'api', 'sidekiq']);

local commonHeader(
  group,
  extraTags=[],
  featureCategories,
  featureCategoriesSelector,
  displayControllerFilter,
  displayGroupFilter,
  enabledRequestComponents,
  displayEmptyGuidance,
  displayBudget,
  title,
      ) =
  basic
  .dashboard(
    title,
    tags=['feature_category'] + extraTags,
    time_from='now-6h/m',
    time_to='now/m'
  )
  .addTemplate(prebuiltTemplates.stage)
  .addTemplates(
    if displayControllerFilter && std.length(enabledRequestComponents) != 0 then
      [controllerFilter(featureCategoriesSelector), actionFilter(featureCategoriesSelector)]
    else
      []
  )
  .addTemplates(
    if displayGroupFilter then
      [groupFilter()]
    else
      [groupFilter(hide=true, current=group.key)]
  )
  .addPanels(
    if displayEmptyGuidance then
      layout.rowGrid(
        'Introduction',
        [
          grafana.text.new(
            title='Introduction',
            mode='markdown',
            content=|||
              You may see there are some empty panels in this dashboard. The metrics in each dashboard are filtered and accumulated based on the GitLab [product categories](https://about.gitlab.com/handbook/product/categories/) and [feature categories](https://docs.gitlab.com/ee/development/feature_categorization/index.html).
              - If your stage group hasn't declared a feature category, please follow the feature category guideline.
              - If your stage group doesn't use a particular component, you can always [customize this dashboard](https://docs.gitlab.com/ee/development/stage_group_dashboards.html#how-to-customize-the-dashboard) to exclude irrelevant panels.

              For more information, please visit [Dashboards for stage groups](https://docs.gitlab.com/ee/development/stage_group_dashboards.html) or watch [Guide to getting started with dashboards for stage groups](https://youtu.be/xB3gHlKCZpQ).

              The dashboards for stage groups are at a very early stage. All contributions are welcome. If you have any questions or suggestions, please submit an issue in the [Scalability Team issues tracker](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/new).
            |||,
          ),
        ],
        startRow=0
      )
    else
      []
  )
  .addPanels(
    if displayBudget then
      // Errorbudgets are always viewed over a 28d rolling average, regardles of the
      // selected range see the configuration in `libsonnet/stage-groups/error_budget.libsonnet`
      local title = 'Error Budget (past 28 days)';
      layout.splitColumnGrid(errorBudgetPanels(group), startRow=100, cellHeights=[4, 2], title=title) +
      layout.rowGrid('Budget spend attribution', errorBudgetAttribution(group, featureCategories), startRow=110, collapse=true)
    else
      []
  );

local getEnabledRequestComponents(components) =
  assert std.type(components) == 'array' : 'Invalid components argument type';

  local setComponents = std.set(components);
  local invalidComponents = std.setDiff(setComponents, supportedComponents);
  assert std.length(invalidComponents) == 0 :
         'Invalid components: ' + std.join(', ', invalidComponents);

  std.setInter(requestComponents, setComponents);

local dashboard(groupKey, components=defaultComponents, displayEmptyGuidance=false, displayBudget=true) =
  local group = stages.stageGroup(groupKey);
  local featureCategories = stages.categoriesForStageGroup(groupKey);
  local featureCategoriesSelector = std.join('|', featureCategories);
  local enabledRequestComponents = getEnabledRequestComponents(components);

  local dashboard =
    commonHeader(
      group=group,
      featureCategories=featureCategories,
      featureCategoriesSelector=featureCategoriesSelector,
      displayControllerFilter=true,
      displayGroupFilter=false,
      enabledRequestComponents=enabledRequestComponents,
      displayEmptyGuidance=displayEmptyGuidance,
      displayBudget=displayBudget,
      title=std.format('Group dashboard: %s (%s)', [group.stage, group.name]),
    )
    .addPanels(
      if std.length(enabledRequestComponents) != 0 then
        layout.rowGrid(
          'Rails Request Rates',
          [
            railsRequestRate(component, featureCategories, featureCategoriesSelector)
            for component in enabledRequestComponents
          ] +
          [
            grafana.text.new(
              title='Extra links',
              mode='markdown',
              content=toolingLinks.generateMarkdown([
                toolingLinks.kibana(
                  title='Kibana Rails',
                  index='rails',
                  matches={
                    'json.meta.feature_category': featureCategories,
                  },
                ),
                toolingLinks.sentry(slug='gitlab/gitlabcom', featureCategories=featureCategories, variables=['environment', 'stage']),
              ], { prometheusSelectorHash: {} })
            ),
          ],
          startRow=201
        )
        +
        layout.rowGrid(
          'Rails 95th Percentile Request Latency',
          [
            railsP95RequestLatency(component, featureCategories, featureCategoriesSelector)
            for component in enabledRequestComponents
          ],
          startRow=301
        )
        +
        layout.rowGrid(
          'Rails Error Rates (accumulated by components)',
          [
            railsErrorRate(component, featureCategories, featureCategoriesSelector)
            for component in enabledRequestComponents
          ],
          startRow=401
        )
        +
        layout.rowGrid(
          'SQL Queries Per Action',
          [
            sqlQueriesPerAction(component, featureCategories, featureCategoriesSelector)
            for component in enabledRequestComponents
          ],
          startRow=501
        )
        +
        layout.rowGrid(
          'SQL Latency Per Action',
          [
            sqlLatenciesPerAction(component, featureCategories, featureCategoriesSelector)
            for component in enabledRequestComponents
          ],
          startRow=601
        )
        +
        layout.rowGrid(
          'SQL Latency Per Query',
          [
            sqlLatenciesPerQuery(component, featureCategories, featureCategoriesSelector)
            for component in enabledRequestComponents
          ],
          startRow=701
        )
        +
        layout.rowGrid(
          'Caches per Action',
          [
            cachesPerAction(component, featureCategories, featureCategoriesSelector)
            for component in enabledRequestComponents
          ],
          startRow=801
        )
      else
        []
    )
    .addPanels(
      if std.member(components, 'sidekiq') then
        layout.rowGrid(
          'Sidekiq',
          [
            sidekiqJobRate(
              'sidekiq_jobs_completion_seconds_count',
              'Sidekiq Completion Rate',
              'The rate (Jobs per Second) at which jobs are completed after dequeue',
              featureCategoriesSelector
            ),
            sidekiqJobRate(
              'sidekiq_jobs_failed_total',
              'Sidekiq Error Rate',
              'The rate (Jobs per Second) at which jobs fail after dequeue',
              featureCategoriesSelector
            ),
            grafana.text.new(
              title='Extra links',
              mode='markdown',
              content=toolingLinks.generateMarkdown([
                toolingLinks.kibana(
                  title='Kibana Sidekiq',
                  index='sidekiq',
                  matches={
                    'json.meta.feature_category': featureCategories,
                  },
                ),
                toolingLinks.sentry(slug='gitlab/gitlabcom', type='sidekiq', featureCategories=featureCategories, variables=['environment', 'stage']),
              ], { prometheusSelectorHash: {} })
            ),
          ],
          startRow=901
        )
      else
        []
    );

  dashboard {
    stageGroupDashboardTrailer()::
      // Add any additional trailing panels here
      self.trailer(),
    links+:
      [
        platformLinks.dynamicLinks('Detail', 'stage-group-error-budget-detail', asDropdown=false),
        platformLinks.dynamicLinks('API Detail', 'type:api'),
        platformLinks.dynamicLinks('Web Detail', 'type:web'),
        platformLinks.dynamicLinks('Git Detail', 'type:git'),
      ],
    addSidekiqJobDurationByUrgency(urgencies=['high', 'low'])::
      self.addPanels(sidekiqJobDurationByUrgency(urgencies, featureCategoriesSelector)),
  };

local errorBudgetDetailDashboard() =
  local dashboard =
    commonHeader(
      group={ key: '$stage_group', name: 'this group' },
      extraTags=['stage-group-error-budget-detail'],
      featureCategories=[],
      featureCategoriesSelector=null,
      displayControllerFilter=false,
      displayGroupFilter=true,
      enabledRequestComponents=requestComponents,
      displayEmptyGuidance=false,
      displayBudget=true,
      title='Stage group error budget detail',
    )
    .addPanels(
      keyMetrics.headlineMetricsRow(
        startRow=200,
        serviceType=null,
        selectorHash={
          environment: '$environment',
          stage: '$stage',
          stage_group: '$stage_group',
        },
        staticTitlePrefix='Overall',
        // Change this to be dynamic when stage group is not a template variable:
        // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1365
        legendFormatPrefix='Stage group',
        aggregationSet=aggregationSets.stageGroupSLIs,
        showApdex=true,
        showErrorRatio=true,
        showOpsRate=true,
        showSaturationCell=false,
        skipDescriptionPanels=true,
        includeLastWeek=false,
        compact=true,
        rowHeight=8,
      )
    )
    .addPanels(
      metricsCatalogDashboards.sliMatrixAcrossServices(
        title='🔬 Service Level Indicators',
        serviceTypes=requestComponents,
        aggregationSet=aggregationSets.serviceComponentStageGroupSLIs,
        startRow=300,
        expectMultipleSeries=true,
        legendFormatPrefix='{{ type }}',
        selectorHash={
          environment: '$environment',
          stage: '$stage',
          stage_group: '$stage_group',
        },
        // Use feature_category significant label as a proxy for 'can be rolled
        // up to stage group'. We can't use
        // `sli.hasFeatureCategoryFromSourceMetrics because the `puma`
        // component has `featureCategory: 'not_owned'`. This is because the
        // `error` part of that SLI has a feature category, while the apdex side
        // does not. That's included in the `rails_requests` component. We
        // should revisit this when we adjust the way we track these errors.
        // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1230
        sliFilter=function(sli) std.member(sli.significantLabels, 'feature_category')
      )
    )
    .addPanels(
      metricsCatalogDashboards.autoDetailRowsAcrossServices(
        serviceTypes=requestComponents,
        selectorHash={
          environment: '$environment',
          stage: '$stage',
          // TODO: fix this once we have a dashboard per stage group:
          // https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1365
          feature_category: { re: 'team_planning|planning_analytics' },
        },
        startRow=1200,
        sliFilter=function(sli) std.member(sli.significantLabels, 'feature_category')
      )
    );

  dashboard {
    stageGroupDashboardTrailer()::
      // Add any additional trailing panels here
      self.trailer(),
    links+:
      [
        platformLinks.dynamicLinks('API Detail', 'type:api'),
        platformLinks.dynamicLinks('Web Detail', 'type:web'),
        platformLinks.dynamicLinks('Git Detail', 'type:git'),
      ],
  };

{
  // dashboard generates a basic stage group dashboard for a stage group
  // The group should match a group a `stage` from `./services/stage-group-mapping.jsonnet`
  dashboard: dashboard,
  errorBudgetDetailDashboard: errorBudgetDetailDashboard,
  supportedComponents: supportedComponents,
}
