local stageGroupDashboards = import './stage-group-dashboards.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testDefaultComponents: {
    actual: stageGroupDashboards.dashboard('geo').stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == [
        'Rails Request Rates',
        'API Request Rate',
        'GIT Request Rate',
        'WEB Request Rate',
        'Extra links',
        'Rails Error Rates (accumulated by components)',
        'API Error Rate',
        'GIT Error Rate',
        'WEB Error Rate',
        'SQL Queries Per Action',
        'SQL Latency Per Action',
        'SQL Latency Per Query',
        'Caches per Action',
        'Sidekiq',
        'Sidekiq Completion Rate',
        'Sidekiq Error Rate',
        'Extra links',
        'Source',
      ] &&
      [template.name for template in results.templating.list] == [
        'PROMETHEUS_DS',
        'environment',
        'controller',
        'action',
      ],
  },
  testDisplayEmptyGuidance: {
    actual: stageGroupDashboards.dashboard('geo', displayEmptyGuidance=true).stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == [
        'Introduction',
        'Introduction',
        'Rails Request Rates',
        'API Request Rate',
        'GIT Request Rate',
        'WEB Request Rate',
        'Extra links',
        'Rails Error Rates (accumulated by components)',
        'API Error Rate',
        'GIT Error Rate',
        'WEB Error Rate',
        'SQL Queries Per Action',
        'SQL Latency Per Action',
        'SQL Latency Per Query',
        'Caches per Action',
        'Sidekiq',
        'Sidekiq Completion Rate',
        'Sidekiq Error Rate',
        'Extra links',
        'Source',
      ] &&
      [template.name for template in results.templating.list] == [
        'PROMETHEUS_DS',
        'environment',
        'controller',
        'action',
      ],
  },
  testWeb: {
    actual: stageGroupDashboards.dashboard('geo', components=['web']).stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == [
        'Rails Request Rates',
        'WEB Request Rate',
        'Extra links',
        'Rails Error Rates (accumulated by components)',
        'WEB Error Rate',
        'SQL Queries Per Action',
        'SQL Latency Per Action',
        'SQL Latency Per Query',
        'Caches per Action',
        'Source',
      ] &&
      [template.name for template in results.templating.list] == [
        'PROMETHEUS_DS',
        'environment',
        'controller',
        'action',
      ],
  },
  testApiWeb: {
    actual: stageGroupDashboards.dashboard('geo', components=['api', 'web']).stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == [
        'Rails Request Rates',
        'API Request Rate',
        'WEB Request Rate',
        'Extra links',
        'Rails Error Rates (accumulated by components)',
        'API Error Rate',
        'WEB Error Rate',
        'SQL Queries Per Action',
        'SQL Latency Per Action',
        'SQL Latency Per Query',
        'Caches per Action',
        'Source',
      ] &&
      [template.name for template in results.templating.list] == [
        'PROMETHEUS_DS',
        'environment',
        'controller',
        'action',
      ],
  },
  testSidekiq: {
    actual: stageGroupDashboards.dashboard('geo', components=['sidekiq']).stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == [
        'Sidekiq',
        'Sidekiq Completion Rate',
        'Sidekiq Error Rate',
        'Extra links',
        'Source',
      ] &&
      [template.name for template in results.templating.list if template != {}] == [
        'PROMETHEUS_DS',
        'environment',
      ],
  },
})
