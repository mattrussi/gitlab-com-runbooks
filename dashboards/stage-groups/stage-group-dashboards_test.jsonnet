local stageGroupDashboards = import './stage-group-dashboards.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testDefaultComponents: {
    actual: stageGroupDashboards.dashboard('geo').stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == [
        'Rails request rates',
        'Request rate per action api',
        'Request rate per action git',
        'Request rate per action web',
        'Extra links',
        'Rails error rates',
        'Error rate api',
        'Error rate git',
        'Error rate web',
        'Sidekiq jobs',
        'Sidekiq Completion rate',
        'Sidekiq Error rate',
        'Extra links',
        'Source',
      ],
  },
  testWeb: {
    actual: stageGroupDashboards.dashboard('geo', components=['web']).stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == [
        'Rails request rates',
        'Request rate per action web',
        'Extra links',
        'Rails error rates',
        'Error rate web',
        'Source',
      ],
  },
  testApiWeb: {
    actual: stageGroupDashboards.dashboard('geo', components=['api', 'web']).stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == [
        'Rails request rates',
        'Request rate per action api',
        'Request rate per action web',
        'Extra links',
        'Rails error rates',
        'Error rate api',
        'Error rate web',
        'Source',
      ],
  },
  testSidekiq: {
    actual: stageGroupDashboards.dashboard('geo', components=['sidekiq']).stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == [
        'Sidekiq jobs',
        'Sidekiq Completion rate',
        'Sidekiq Error rate',
        'Extra links',
        'Source',
      ],
  },
})
