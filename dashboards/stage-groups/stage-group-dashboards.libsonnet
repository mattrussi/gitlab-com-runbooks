local stages = import '../../services/stages.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local prebuiltTemplates = import 'grafana/templates.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local platformLinks = import '../platform_links.libsonnet';
local singleMetricRow = import 'key-metric-panels/single-metric-row.libsonnet';
local aggregationSets = import '../../metrics-catalog/aggregation-sets.libsonnet';
local errorBudget = import 'stage-groups/error_budget.libsonnet';

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

local errorBudgetPanels(group) =
  [
    errorBudget.availabilityStatPanel(group.key, '28d'),
    errorBudget.timeSpentStatPanel(group.key, '28d'),
    grafana.text.new(
      title='Info',
      mode='markdown',
      content=|||
        These error budget panels show an aggregate of SLIs across all components.
        Though not all components have been implemented yet.

        Read more about how the error budgets are calculated in the
        [stage group dashboard documentation](https://docs.gitlab.com/ee/development/stage_group_dashboards.html#error-budget).

        The [handbook](https://about.gitlab.com/handbook/engineering/error-budgets/)
        explains how these budgets are used.

        The error budget is compared to our SLO of %(slaTarget)s and is always in
        a range of 28 days from the selected end date in Grafana.

        ### Availability

        The availability shows the percentage operations labeled with one of the
        categories owned by %(groupName)s comleted satisfactory.

        ### Budget spent

        The budget spent shows the time spent during the past 28 days on operations
        that did not complete satisfactory.

        For example, if there were 43200 (28 * 24 * 60) operations for %(groupName)s the last
        28 days, and 10 of them did not meet SLO, this means 10 minutes were spent.
      ||| % {
        slaTarget: '%.2f%%' % (errorBudget.slaTarget * 100.0),
        groupName: group.name,
      },
    ),
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
        gitlab:component:feature_category:execution:error:rate_1m{
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
      sum without (fqdn,instance) (
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

local requestComponents = std.set(['web', 'api', 'git']);
local backgroundComponents = std.set(['sidekiq']);
local validComponents = std.setUnion(requestComponents, backgroundComponents);
local dashboard(groupKey, components=validComponents, displayEmptyGuidance=false, displayBudget=true) =
  assert std.type(components) == 'array' : 'Invalid components argument type';

  local setComponents = std.set(components);
  local invalidComponents = std.setDiff(setComponents, validComponents);
  assert std.length(invalidComponents) == 0 :
         'Invalid components: ' + std.join(', ', invalidComponents);

  local group = stages.stageGroup(groupKey);
  local featureCategories = stages.categoriesForStageGroup(groupKey);
  local featureCategoriesSelector = std.join('|', featureCategories);

  local enabledRequestComponents = std.setInter(requestComponents, setComponents);
  local typeSelector = std.join('|', enabledRequestComponents);

  local dashboard =
    basic
    .dashboard(
      std.format('Group dashboard: %s (%s)', [group.stage, group.name]),
      tags=['feature_category'],
      time_from='now-6h/m',
      time_to='now/m'
    )
    .addTemplate(prebuiltTemplates.stage)
    .addTemplates(
      if std.length(enabledRequestComponents) != 0 then
        [controllerFilter(featureCategoriesSelector), actionFilter(featureCategoriesSelector)]
      else
        []
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
        layout.rowGrid('Error Budgets', errorBudgetPanels(group), startRow=100, rowHeight=5)
      else
        []
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
      if std.member(setComponents, 'sidekiq') then
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
        platformLinks.dynamicLinks('API Detail', 'type:api'),
        platformLinks.dynamicLinks('Web Detail', 'type:web'),
        platformLinks.dynamicLinks('Git Detail', 'type:git'),
      ],
  };

{
  // dashboard generates a basic stage group dashboard for a stage group
  // The group should match a group a `stage` from `./services/stage-group-mapping.jsonnet`
  dashboard: dashboard,
}
