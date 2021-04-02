local stageGroupDashboards = import './stage-group-dashboards.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

local errorBudgetTitles = [
  'Error Budgets',
];

test.suite({
  testDefaultComponents: {
    actual: stageGroupDashboards.dashboard('geo').stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == errorBudgetTitles + [
        'Rails Request Rates',
        'API Request Rate',
        'GIT Request Rate',
        'WEB Request Rate',
        'Extra links',
        'Rails 95th Percentile Request Latency',
        'API 95th Percentile Request Latency',
        'GIT 95th Percentile Request Latency',
        'WEB 95th Percentile Request Latency',
        'Rails Error Rates (accumulated by components)',
        'API Error Rate',
        'GIT Error Rate',
        'WEB Error Rate',
        'SQL Queries Per Action',
        'API SQL Queries per Action',
        'GIT SQL Queries per Action',
        'WEB SQL Queries per Action',
        'SQL Latency Per Action',
        'API SQL Latency per Action',
        'GIT SQL Latency per Action',
        'WEB SQL Latency per Action',
        'SQL Latency Per Query',
        'API SQL Latency per Query',
        'GIT SQL Latency per Query',
        'WEB SQL Latency per Query',
        'Caches per Action',
        'API Caches per Action',
        'GIT Caches per Action',
        'WEB Caches per Action',
        'Sidekiq',
        'Sidekiq Completion Rate',
        'Sidekiq Error Rate',
        'Extra links',
        'Source',
      ] &&
      [template.name for template in results.templating.list] == [
        'PROMETHEUS_DS',
        'environment',
        'stage',
        'controller',
        'action',
      ],
  },
  testDisplayEmptyGuidance: {
    actual: stageGroupDashboards.dashboard('geo', displayEmptyGuidance=true).stageGroupDashboardTrailer(),
    expectThat: function(results)
      local introPanels = [
        'Introduction',
        'Introduction',
      ];
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == introPanels +
                                                   errorBudgetTitles + [
        'Rails Request Rates',
        'API Request Rate',
        'GIT Request Rate',
        'WEB Request Rate',
        'Extra links',
        'Rails 95th Percentile Request Latency',
        'API 95th Percentile Request Latency',
        'GIT 95th Percentile Request Latency',
        'WEB 95th Percentile Request Latency',
        'Rails Error Rates (accumulated by components)',
        'API Error Rate',
        'GIT Error Rate',
        'WEB Error Rate',
        'SQL Queries Per Action',
        'API SQL Queries per Action',
        'GIT SQL Queries per Action',
        'WEB SQL Queries per Action',
        'SQL Latency Per Action',
        'API SQL Latency per Action',
        'GIT SQL Latency per Action',
        'WEB SQL Latency per Action',
        'SQL Latency Per Query',
        'API SQL Latency per Query',
        'GIT SQL Latency per Query',
        'WEB SQL Latency per Query',
        'Caches per Action',
        'API Caches per Action',
        'GIT Caches per Action',
        'WEB Caches per Action',
        'Sidekiq',
        'Sidekiq Completion Rate',
        'Sidekiq Error Rate',
        'Extra links',
        'Source',
      ] &&
      [template.name for template in results.templating.list] == [
        'PROMETHEUS_DS',
        'environment',
        'stage',
        'controller',
        'action',
      ],
  },
  testWeb: {
    actual: stageGroupDashboards.dashboard('geo', components=['web']).stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == errorBudgetTitles + [
        'Rails Request Rates',
        'WEB Request Rate',
        'Extra links',
        'Rails 95th Percentile Request Latency',
        'WEB 95th Percentile Request Latency',
        'Rails Error Rates (accumulated by components)',
        'WEB Error Rate',
        'SQL Queries Per Action',
        'WEB SQL Queries per Action',
        'SQL Latency Per Action',
        'WEB SQL Latency per Action',
        'SQL Latency Per Query',
        'WEB SQL Latency per Query',
        'Caches per Action',
        'WEB Caches per Action',
        'Source',
      ] &&
      [template.name for template in results.templating.list] == [
        'PROMETHEUS_DS',
        'environment',
        'stage',
        'controller',
        'action',
      ],
  },
  testApiWeb: {
    actual: stageGroupDashboards.dashboard('geo', components=['api', 'web']).stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == errorBudgetTitles + [
        'Rails Request Rates',
        'API Request Rate',
        'WEB Request Rate',
        'Extra links',
        'Rails 95th Percentile Request Latency',
        'API 95th Percentile Request Latency',
        'WEB 95th Percentile Request Latency',
        'Rails Error Rates (accumulated by components)',
        'API Error Rate',
        'WEB Error Rate',
        'SQL Queries Per Action',
        'API SQL Queries per Action',
        'WEB SQL Queries per Action',
        'SQL Latency Per Action',
        'API SQL Latency per Action',
        'WEB SQL Latency per Action',
        'SQL Latency Per Query',
        'API SQL Latency per Query',
        'WEB SQL Latency per Query',
        'Caches per Action',
        'API Caches per Action',
        'WEB Caches per Action',
        'Source',
      ] &&
      [template.name for template in results.templating.list] == [
        'PROMETHEUS_DS',
        'environment',
        'stage',
        'controller',
        'action',
      ],
  },
  testSidekiq: {
    actual: stageGroupDashboards.dashboard('geo', components=['sidekiq']).stageGroupDashboardTrailer(),
    expectThat: function(results)
      results.title == 'Group dashboard: enablement (Geo)' &&
      std.type(results.panels) == 'array' &&
      [panel.title for panel in results.panels] == errorBudgetTitles + [
        'Sidekiq',
        'Sidekiq Completion Rate',
        'Sidekiq Error Rate',
        'Extra links',
        'Source',
      ] &&
      [template.name for template in results.templating.list if template != {}] == [
        'PROMETHEUS_DS',
        'environment',
        'stage',
      ],
  },
})
