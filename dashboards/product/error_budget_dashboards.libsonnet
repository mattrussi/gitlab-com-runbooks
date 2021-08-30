local basic = import 'gitlab-monitoring/grafana/basic.libsonnet';
local layout = import 'gitlab-monitoring/grafana/layout.libsonnet';
local prebuiltTemplates = import 'gitlab-monitoring/grafana/templates.libsonnet';
local stages = import 'service-catalog/stages.libsonnet';
local errorBudget = import 'stage-groups/error_budget.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local groupDashboardLink(group) =
  toolingLinks.generateMarkdown([
    toolingLinks.grafana(
      "%(group)s's group dashboard" % group.name,
      toolingLinks.grafanaUid('stage-groups/%s.jsonnet' % group.key),
    ),
  ]);

local normalizeUrl(url) = std.strReplace(url, '_', '-');

local groupHandbookLink = function(group)
  normalizeUrl('https://about.gitlab.com/handbook/product/categories/#%s-group' % group.key);

local errorBudgetPanels(group) =
  [
    [
      errorBudget.panels.availabilityStatPanel(group.key),
      errorBudget.panels.availabilityTargetStatPanel(group.key),
    ],
    [
      errorBudget.panels.timeRemainingStatPanel(group.key),
      errorBudget.panels.timeRemainingTargetStatPanel(group.key),
    ],
    [
      errorBudget.panels.timeSpentStatPanel(group.key),
      errorBudget.panels.timeSpentTargetStatPanel(group.key),
    ],
    [
      basic.text(
        title='Extra links',
        content=|||
          - [%(group)s's handbook page](%(handbookLink)s)
          %(groupDashboardLink)s
        ||| % {
          group: group.name,
          groupDashboardLink: groupDashboardLink(group),
          handbookLink: groupHandbookLink(group),
        }
      ),
    ],
  ];

local selectGroups(stage, groups) =
  local setGroups = std.set(groups);
  local validGroups = std.set(
    std.map(
      function(stage) stage.key,
      stages.groupsForStage(stage)
    )
  );

  local invalidGroups = std.setDiff(setGroups, validGroups);
  assert std.length(invalidGroups) == 0 : 'Groups not in %(stage)s: %(groups)s' % {
    groups: std.join(', ', invalidGroups),
    stage: stage,
  };

  std.map(function(groupName) stages.stageGroup(groupName), groups);

local dashboard(stage, groups=null, range=errorBudget.range) =
  assert std.type(groups) == 'null' || std.type(groups) == 'array' : 'Invalid groups argument type';

  local stageGroups =
    if groups == null then
      stages.groupsForStage(stage)
    else
      selectGroups(stage, groups);

  local basicDashboard = basic.dashboard(
    title='Error Budgets - %s' % stage,
    time_from='now-%s' % range,
    tags=['product performance']
  ).addTemplate(
    prebuiltTemplates.stage
  ).addPanel(
    errorBudget.panels.explanationPanel(stage),
    gridPos={ x: 0, y: (std.length(stageGroups) + 1) * 100, w: 24, h: 6 },
  );

  std.foldl(
    function(d, groupWrapper)
      d.addPanels(
        local group = groupWrapper.group;
        local rowIndex = (groupWrapper.index + 1) * 100;
        local title = "%(group)s's Error Budgets (past %(range)s)" % {
          group: group.name,
          range: range,
        };
        layout.splitColumnGrid(errorBudgetPanels(group), startRow=rowIndex, cellHeights=[4, 2], title=title)
      ),
    std.mapWithIndex(
      function(index, group) { group: group, index: index },
      stageGroups
    ),
    basicDashboard
  );

{
  dashboard: dashboard,
}
