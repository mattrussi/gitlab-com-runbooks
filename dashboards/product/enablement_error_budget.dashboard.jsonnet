local errorBudgetsDashboards = import './error_budget_dashboards.libsonnet';

errorBudgetsDashboards
.dashboard('enablement', groups=['geo', 'global_search'])
.trailer()
