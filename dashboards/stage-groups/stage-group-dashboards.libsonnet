local stages = import '../../services/stages.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local metrics = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local controllerFilter(featureCategoriesSelector) =
  template.new(
    'controller',
    '$PROMETHEUS_DS',
    "label_values(controller_action:gitlab_transaction_duration_seconds_count:rate1m{environment='$environment', feature_category=~'(%s)', }, controller)" % featureCategoriesSelector,
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
    "label_values(controller_action:gitlab_transaction_duration_seconds_count:rate1m{environment='$environment', controller=~'$controller', feature_category=~'(%s)', }, action)" % featureCategoriesSelector,
    current=null,
    refresh='load',
    sort=1,
    multi=true,
    includeAll=true,
    allValues='.*'
  );

local railsRequestRate(type, featureCategories, featureCategoriesSelector) =
  basic.timeseries(
    title='%(type)s Request Rate' % { type: std.asciiUpper(type) },
    yAxisLabel='Requests per Second',
    legendFormat=if type == 'api' then '{{action}}' else '{{controller}}#{{action}}',
    decimals=2,
    query=|||
      sum by (controller, action) (
        rate(gitlab_transaction_duration_seconds_count{
          env='$environment',
          environment='$environment',
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
          env='$environment',
          environment='$environment',
          feature_category=~'(%(featureCategories)s)',
          type='%(type)s'
        }
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
          env='$environment',
          environment='$environment',
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
local dashboard(groupKey, components=validComponents, displayEmptyGuidance=false) =
  assert std.type(components) == 'array' : 'Invalid components argument type';
  assert std.length(components) != 0 : 'There must be at least one component';

  local setComponents = std.set(components);
  local invalidComponents = std.setDiff(setComponents, validComponents);
  assert std.length(invalidComponents) == 0 :
         'Invalid components: ' + std.join(', ', invalidComponents);

  local group = stages.stageGroup(groupKey);
  local featureCategories = stages.categoriesForStageGroup(groupKey);
  local featureCategoriesSelector = std.join('|', featureCategories);

  local enabledRequestComponents = std.setInter(requestComponents, setComponents);

  local dashboard =
    basic
    .dashboard(
      std.format('Group dashboard: %s (%s)', [group.stage, group.name]),
      tags=['feature_category'],
      time_from='now-6h/m',
      time_to='now/m'
    )
    .addTemplate(
      if std.length(enabledRequestComponents) != 0 then
        controllerFilter(featureCategoriesSelector)
      else
        {}
    )
    .addTemplate(
      if std.length(enabledRequestComponents) != 0 then
        actionFilter(featureCategoriesSelector)
      else
        {}
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
      else
        []
    )
    .addPanels(
      if std.length(enabledRequestComponents) != 0 then
        layout.rowGrid(
          'Rails Error Rates (accumulated by components)',
          [
            railsErrorRate(component, featureCategories, featureCategoriesSelector)
            for component in enabledRequestComponents
          ],
          startRow=301
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
          startRow=401
        )
      else
        []
    );

  dashboard {
    stageGroupDashboardTrailer()::
      // Add any additional trailing panels here
      self.trailer(),
  };

{
  // dashboard generates a basic stage group dashboard for a stage group
  // The group should match a group a `stage` from `./services/stage-group-mapping.jsonnet`
  dashboard: dashboard,
}
