local stages = import '../../services/stages.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local metrics = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

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
      type='%(type)s'
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
    legendFormat=if type == 'api' then '{{action}}' else '{{controller}}#{{action}}',
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

local validComponents = std.set(['web', 'api', 'git', 'sidekiq']);
local dashboard(groupKey, components=validComponents) =
  assert std.type(components) == 'array' : 'Invalid components argument type';
  assert std.length(components) != 0 : 'There must be at least one component';

  local setComponents = std.set(components);
  local invalidComponents = std.setDiff(setComponents, validComponents);
  assert std.length(invalidComponents) == 0 :
         'Invalid components: ' + std.join(', ', invalidComponents);

  local group = stages.stageGroup(groupKey);
  local featureCategories = stages.categoriesForStageGroup(groupKey);
  local featureCategoriesSelector = std.join('|', featureCategories);

  local dashboard =
    basic
    .dashboard(
      std.format('Group dashboard: %s (%s)', [group.stage, group.name]),
      tags=['feature_category'],
      time_from='now-6h/m',
      time_to='now/m'
    )
    .addPanels(
      local requestRateComponents = std.setInter(std.set(['web', 'api', 'git']), setComponents);
      if std.length(requestRateComponents) != 0 then
        layout.rowGrid(
          'Rails Request Rates',
          [
            railsRequestRate(component, featureCategories, featureCategoriesSelector)
            for component in requestRateComponents
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
      local errorRateComponents = std.setInter(std.set(['web', 'api', 'git']), setComponents);
      if std.length(errorRateComponents) != 0 then
        layout.rowGrid(
          'Rails Error Rates',
          [
            railsErrorRate(component, featureCategories, featureCategoriesSelector)
            for component in errorRateComponents
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
