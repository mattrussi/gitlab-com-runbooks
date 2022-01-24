local stageGroupDashboards = import '../stage-groups/stage-group-dashboards.libsonnet';
local stageGroupMapping = (import 'gitlab-metrics-config.libsonnet').stageGroupMapping;

std.foldl(
  function(memo, stageGroupKey)
    local stageGroup = stageGroupMapping[stageGroupKey] { key: stageGroupKey };

    memo {
      [stageGroupKey]: stageGroupDashboards.errorBudgetDetailDashboard(stageGroup),
    },
  std.objectFields(stageGroupMapping),
  {}
)
