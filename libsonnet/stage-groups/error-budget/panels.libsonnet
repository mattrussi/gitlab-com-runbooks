local utils = import './utils.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local queries = import 'stage-groups/error-budget/queries.libsonnet';
local durationParser = import 'utils/duration-parser.libsonnet';

local baseSelector = {
  stage: '$stage',
  environment: '$environment',
  monitor: 'global',
};

local thresholds(slaTarget, range) =
  local definitions = [
    {
      availability: {
        from: 0,
        to: slaTarget,
      },
      secondsRemaining: {
        from: 0 - durationParser.toSeconds(range),
        to: 0,
      },
      secondsSpent: {
        from: utils.budgetSeconds(slaTarget, range),
        to: durationParser.toSeconds(range),
      },
      color: 'red',
      text: '🥵 Unhealthy',
    },
    {
      availability: {
        from: slaTarget,
        to: 1.0,
      },
      secondsRemaining: {
        from: 0,
        to: utils.budgetSeconds(slaTarget, range),
      },
      secondsSpent: {
        from: 0,
        to: utils.budgetSeconds(slaTarget, range),
      },
      color: 'green',
      text: '🥳 Healthy',
    },
  ];
  local thresholdStep(color, value) = { color: color, value: value };
  local steps(type) =
    std.map(
      function(definition) thresholdStep(definition.color, definition[type].from),
      std.sort(definitions, function(definition) definition[type].from)
    );
  local mapping(color, from, to, text) = {
    from: from,
    to: to,
    color: color,
    text: text,
    type: 2,  // Range: https://grafana.com/docs/grafana/latest/packages_api/data/mappingtype/
  };
  local mappings(type) =
    std.map(
      function(definition) mapping(definition.color, definition[type].from, definition[type].to, definition.text),
      definitions
    );

  {
    stepsFor(type): steps(type),
    mappingsFor(type): mappings(type),
  };


local availabilityStatPanel(queries, slaTarget, range, groupSelectors) =
  basic.statPanel(
    '',
    'Availability',
    thresholds(slaTarget, range).stepsFor('availability'),
    query=queries.errorBudgetRatio(
      baseSelector {
        stage_group: groupSelectors,
      },
    ),
    legendFormat='%',
    decimals=2,
    unit='percentunit',
  );

local availabilityTargetStatPanel(queries, slaTarget, range, groupSelectors) =
  basic.statPanel(
    'Target: %(targetRatio).2f%%' % { targetRatio: slaTarget * 100.0 },
    '',
    thresholds(slaTarget, range).stepsFor('availability'),
    mappings=thresholds(slaTarget, range).mappingsFor('availability'),
    query=queries.errorBudgetRatio(
      baseSelector {
        stage_group: groupSelectors,
      },
    ),
    legendFormat='',
    unit='none',
    decimals='2'
  );

local timeRemainingTargetStatPanel(queries, slaTarget, range, groupSelectors) =
  basic.statPanel(
    '%(range)s budget: %(budgetMinutes).0f minutes' % {
      budgetMinutes: (utils.budgetSeconds(slaTarget, range) / 60.0),
      range: range,
    },
    '',
    thresholds(slaTarget, range).stepsFor('secondsRemaining'),
    mappings=thresholds(slaTarget, range).mappingsFor('secondsRemaining'),
    query=queries.errorBudgetTimeRemaining(
      baseSelector {
        stage_group: groupSelectors,
      },
    ),
    legendFormat='',
    unit='none',
    decimals='2'
  );

local timeRemainingStatPanel(queries, slaTarget, range, groupSelectors) =
  basic.statPanel(
    '',
    'Budget remaining',
    thresholds(slaTarget, range).stepsFor('secondsRemaining'),
    query=queries.errorBudgetTimeRemaining(
      baseSelector {
        stage_group: groupSelectors,
      },
    ),
    legendFormat='',
    unit='s',
  );

local timeSpentStatPanel(queries, slaTarget, range, groupSelectors) =
  basic.statPanel(
    '',
    'Budget spent',
    thresholds(slaTarget, range).stepsFor('secondsSpent'),
    query=queries.errorBudgetTimeSpent(
      baseSelector {
        stage_group: groupSelectors,
      },
    ),
    legendFormat='',
    unit='s',
  );

local timeSpentTargetStatPanel(queries, slaTarget, range, groupSelectors) =
  basic.statPanel(
    'Target: Less than %(budgetMinutes).0f minutes in %(range)s' % {
      budgetMinutes: (utils.budgetSeconds(slaTarget, range) / 60.0),
      range: range,
    },
    '',
    thresholds(slaTarget, range).stepsFor('secondsSpent'),
    mappings=thresholds(slaTarget, range).mappingsFor('secondsSpent'),
    query=queries.errorBudgetTimeSpent(
      baseSelector {
        stage_group: groupSelectors,
      },
    ),
    legendFormat='',
    unit='none',
    decimals='2'
  );

{
  init(queries, slaTarget, range):: {
    availabilityStatPanel(group)::
      availabilityStatPanel(queries, slaTarget, range, group),
    availabilityTargetStatPanel(group)::
      availabilityTargetStatPanel(queries, slaTarget, range, group),
    timeSpentStatPanel(group)::
      timeSpentStatPanel(queries, slaTarget, range, group),
    timeRemainingStatPanel(group)::
      timeRemainingStatPanel(queries, slaTarget, range, group),
    timeRemainingTargetStatPanel(group)::
      timeRemainingTargetStatPanel(queries, slaTarget, range, group),
    timeSpentTargetPanel(group)::
      timeSpentTargetStatPanel(queries, slaTarget, range, group),
    timeSpentTargetStatPanel(group)::
      timeSpentTargetStatPanel(queries, slaTarget, range, group),
  },
}
