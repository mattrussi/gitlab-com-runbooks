local stageGroupDashboards = import '../stage-groups/stage-group-dashboards.libsonnet';

stageGroupDashboards
.errorBudgetDetailDashboard('project_management', components=['api', 'web'])
