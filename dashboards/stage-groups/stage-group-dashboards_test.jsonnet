local stageGroupDashboards = import './stage-group-dashboards.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

local errorBudgetTitles = [
  'Error Budget (past 28 days)',
  'Availability',
  'Budget remaining',
  'Budget spent',
  'Info',
  'Budget spend attribution',
];

local allComponentTitles = [
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
  'Sidekiq',
  'Sidekiq Completion Rate',
  'Sidekiq Error Rate',
  'Extra links',
  'Source',
];

local panelTitles(dashboard) =
  std.filter(function(title) title != '', [panel.title for panel in dashboard.panels]);

test.suite({
  testTemplates: {
    actual: [template.name for template in stageGroupDashboards.dashboard('geo').stageGroupDashboardTrailer().templating.list],
    expect: [
      'PROMETHEUS_DS',
      'environment',
      'stage',
      'controller',
      'action',
    ],
  },

  testTitle: {
    actual: stageGroupDashboards.dashboard('geo').stageGroupDashboardTrailer().title,
    expect: 'Group dashboard: enablement (Geo)',
  },

  testDefaultComponents: {
    actual: panelTitles(stageGroupDashboards.dashboard('geo').stageGroupDashboardTrailer()),
    expect: errorBudgetTitles + allComponentTitles,
  },

  testDisplayEmptyGuidance: {
    introPanels: [
      'Introduction',
      'Introduction',
    ],
    actual: panelTitles(stageGroupDashboards.dashboard('geo', displayEmptyGuidance=true).stageGroupDashboardTrailer()),
    expect: self.introPanels + errorBudgetTitles + allComponentTitles,
  },

  testWeb: {
    webTitles: [
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
    ],
    actual: panelTitles(stageGroupDashboards.dashboard('geo', components=['web']).stageGroupDashboardTrailer()),
    expect: errorBudgetTitles + self.webTitles,
  },

  testApiWeb: {
    apiWebTitles: [
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
    ],
    actual: panelTitles(stageGroupDashboards.dashboard('geo', components=['api', 'web']).stageGroupDashboardTrailer()),
    expect: errorBudgetTitles + self.apiWebTitles,
  },

  testGit: {
    gitTitles: [
      'Rails Request Rates',
      'GIT Request Rate',
      'Extra links',
      'Rails 95th Percentile Request Latency',
      'GIT 95th Percentile Request Latency',
      'Rails Error Rates (accumulated by components)',
      'GIT Error Rate',
      'SQL Queries Per Action',
      'GIT SQL Queries per Action',
      'SQL Latency Per Action',
      'GIT SQL Latency per Action',
      'SQL Latency Per Query',
      'GIT SQL Latency per Query',
      'Caches per Action',
      'GIT Caches per Action',
      'Source',
    ],
    actual: panelTitles(stageGroupDashboards.dashboard('geo', components=['git']).stageGroupDashboardTrailer()),
    expect: errorBudgetTitles + self.gitTitles,
  },

  testSidekiqPanels: {
    sidekiqTitles: [
      'Sidekiq',
      'Sidekiq Completion Rate',
      'Sidekiq Error Rate',
      'Extra links',
      'Source',
    ],
    actual: panelTitles(stageGroupDashboards.dashboard('geo', components=['sidekiq']).stageGroupDashboardTrailer()),
    expect: errorBudgetTitles + self.sidekiqTitles,
  },

  testSidekiqOnlyTemplates: {
    actual: std.prune([template.name for template in stageGroupDashboards.dashboard('geo', components=['sidekiq']).stageGroupDashboardTrailer().templating.list]),
    expect: [
      'PROMETHEUS_DS',
      'environment',
      'stage',
    ],
  },

  testErrorBudgetDetailDashboard: {
    actual: panelTitles(stageGroupDashboards.errorBudgetDetailDashboard({
      key: 'project_management',
      name: 'Project Management',
      stage: 'plan',
      feature_categories: ['team_planning', 'planning_analytics'],
    })),
    expect: [
      'Error Budget (past 28 days)',
      'Availability',
      'Budget remaining',
      'Budget spent',
      'Info',
      'Budget spend attribution',
      '🌡️ Aggregated Service Level Indicators (𝙎𝙇𝙄𝙨)',
      'Overall Apdex',
      'Overall Error Ratio',
      'Overall RPS - Requests per Second',
      '🔬 Service Level Indicators',
      'graphql_queries SLI Apdex',
      'graphql_queries SLI RPS - Requests per Second',
      'Details',
      'puma SLI Error Ratio',
      'puma SLI RPS - Requests per Second',
      'Details',
      'rails_requests SLI Apdex',
      'rails_requests SLI RPS - Requests per Second',
      'Details',
      '🔬 graphql_queries Service Level Indicator Detail',
      '🔬 puma Service Level Indicator Detail',
      '🔬 rails_requests Service Level Indicator Detail',
    ],
  },
})
