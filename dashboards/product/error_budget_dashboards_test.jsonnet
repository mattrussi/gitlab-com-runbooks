local errorBudgetsDashboards = import './error_budget_dashboards.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

local panelTitles(dashboard) =
  std.filter(function(title) title != '', [panel.title for panel in dashboard.panels]);

test.suite({
  testTemplates: {
    actual: [template.name for template in errorBudgetsDashboards.dashboard('plan').trailer().templating.list],
    expect: [
      'PROMETHEUS_DS',
      'environment',
      'stage',
    ],
  },
  testErrorPanelsGeneration: {
    actual: panelTitles(errorBudgetsDashboards.dashboard('plan').trailer()),
    expect: [
      'Info',
      "Certify's Error Budgets (past 28d)",
      'Availability',
      'Budget remaining',
      'Budget spent',
      'Extra links',
      "Product Planning's Error Budgets (past 28d)",
      'Availability',
      'Budget remaining',
      'Budget spent',
      'Extra links',
      "Project Management's Error Budgets (past 28d)",
      'Availability',
      'Budget remaining',
      'Budget spent',
      'Extra links',
      'Source',
    ],
  },
  testErrorPanelsSelectiveGeneration: {
    actual: panelTitles(errorBudgetsDashboards.dashboard('plan', groups=['product_planning', 'certify']).trailer()),
    expect: [
      'Info',
      "Product Planning's Error Budgets (past 28d)",
      'Availability',
      'Budget remaining',
      'Budget spent',
      'Extra links',
      "Certify's Error Budgets (past 28d)",
      'Availability',
      'Budget remaining',
      'Budget spent',
      'Extra links',
      'Source',
    ],
  },
})
