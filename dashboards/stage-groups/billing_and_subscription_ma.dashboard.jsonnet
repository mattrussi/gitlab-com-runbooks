// This file is autogenerated using scripts/update_stage_groups_dashboards.rb
// Please feel free to customize this file.
local stageGroupDashboards = import './stage-group-dashboards.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local stages = (import 'service-catalog/stages.libsonnet');

local groupKey = 'billing_and_subscription_management';
local featureCategories = stages.categoriesForStageGroup(groupKey);

stageGroupDashboards.dashboard(groupKey, components=[])
.addPanels(
  layout.rowGrid(
    'Extra links',
    [
      grafana.text.new(
        title='Rails',
        mode='markdown',
        content=toolingLinks.generateMarkdown([
          toolingLinks.kibana(
            title='Kibana Rails',
            index='rails_cdot',
            matches={
              'json.meta.feature_category': featureCategories,
            },
          ),
        ], { prometheusSelectorHash: {} })
      ),
      grafana.text.new(
        title='Sidekiq',
        mode='markdown',
        content=toolingLinks.generateMarkdown([
          toolingLinks.kibana(
            title='Kibana Sidekiq',
            index='sidekiq_cdot',
            matches={
              'json.meta.feature_category': featureCategories,
            },
          ),
        ], { prometheusSelectorHash: {} })
      ),
    ],
    startRow=201
  )
)
.stageGroupDashboardTrailer()
