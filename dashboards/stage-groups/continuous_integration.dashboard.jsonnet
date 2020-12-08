local stages = import '../../services/stages.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local metrics = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local groupKey = 'continuous_integration';
local group = stages.stageGroup(groupKey);
local featureCategories = stages.categoriesForStageGroup(groupKey);
local featureCategoriesSelector = std.join('|', featureCategories);

local sidekiqJobRate(counter, title) =
  basic.timeseries(
    title=title,
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
// Request rates and error rates for api and git are not included right now
// because requests to Grape endpoints are lacking the feature category label.
// These can be added using these methods after https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/709
// has been resolved.
local railsRequestRate(type) =
  basic.timeseries(
    title='Request rate per action %(type)s' % { type: type },
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

local railsErrorRate(type) =
  basic.timeseries(
    title='Error rate %(type)s' % { type: type },
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

basic.dashboard(
  std.format('Group dashboard: %s (%s)', [group.stage, group.name]),
  tags=['feature_category'],
  time_from='now-6h/m',
  time_to='now/m'
).addPanels(
  layout.rowGrid('Rails request rates', [
    railsRequestRate('web'),
    grafana.text.new(
      title='Extra links',
      mode='markdown',
      content=toolingLinks.generateMarkdown([
        toolingLinks.kibana(
          title='Rails logs',
          index='rails',
          matches={
            'json.meta.feature_category': featureCategories,
          },
        ),
      ], { prometheusSelectorHash: {} })
    ),
  ], startRow=201),
).addPanels(
  layout.rowGrid('Rails error rates', [
    railsErrorRate('web'),
  ], startRow=301),
).addPanels(
  layout.rowGrid('Sidekiq jobs', [
    sidekiqJobRate('sidekiq_jobs_completion_seconds_count', 'Completion rate'),
    sidekiqJobRate('sidekiq_jobs_failed_total', 'Error rate'),
  ], startRow=401)
).trailer()
