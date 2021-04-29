local basic = import 'grafana/basic.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local durationParser = import 'utils/duration-parser.libsonnet';
local slaTarget = (import '../../metrics-catalog/metrics-config.libsonnet').slaTarget;

local baseSelector = {
  stage: '$stage',
  environment: '$environment',
  monitor: 'global',
};

local budgetSeconds(range) = (1 - slaTarget) * durationParser.toSeconds(range);

local thresholds(range) =
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
        from: budgetSeconds(range),
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
        to: budgetSeconds(range),
      },
      secondsSpent: {
        from: 0,
        to: budgetSeconds(range),
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

local errorBudgetRatio(groupSelectors, range) =
  |||
    # Account for missing metrics that are turned into 0 by `vector(0)`.
    clamp_max(
      # Number of successful measurements
      sum(
        # Reuest with satisfactory apdex
        sum_over_time(
          gitlab:component:stage_group:execution:apdex:success:rate_1h{%(selectorHash)s}[%(range)s]
        ) or vector(0)
        +
        # Requests without error
        (
          sum_over_time(
            gitlab:component:stage_group:execution:ops:rate_1h{%(selectorHash)s}[%(range)s]
          )
          -
          sum_over_time(
            gitlab:component:stage_group:execution:error:rate_1h{%(selectorHash)s}[%(range)s]
          ) or vector(0)
        )
      )
      /
      # Number of measurements
      sum(
        # Apdex Measurements
        sum_over_time(
          gitlab:component:stage_group:execution:apdex:weight:score_1h{%(selectorHash)s}[%(range)s]
        ) or vector(0)
        +
        # Requests
        sum_over_time(
          gitlab:component:stage_group:execution:ops:rate_1h{%(selectorHash)s}[%(range)s]
        )
      ),
    1)
  ||| % {
    selectorHash: selectors.serializeHash(groupSelectors),
    range: range,
  };

local errorBudgetTimeSpent(selectors, range) =
  |||
    (
      (
         1 - %(ratioQuery)s
      ) * %(rangeInSeconds)i
    )
  ||| % {
    ratioQuery: errorBudgetRatio(selectors, range),
    rangeInSeconds: durationParser.toSeconds(range),
  };

local errorBudgetTimeRemaining(selectors, range) =
  |||
    # The number of seconds allowed to be spent in %(range)s
    %(budgetSeconds)i
    -
    %(timeSpentQuery)s
  ||| % {
    range: range,
    budgetSeconds: budgetSeconds(range),
    timeSpentQuery: errorBudgetTimeSpent(selectors, range),
  };

local availabilityStatPanel(groupSelectors, range) =
  basic.statPanel(
    '',
    'Availability',
    thresholds(range).stepsFor('availability'),
    query=errorBudgetRatio(
      baseSelector {
        stage_group: groupSelectors,
      },
      range
    ),
    legendFormat='%',
    decimals=2,
    unit='percentunit',
  );

local availabilityTargetStatPanel(groupSelectors, range) =
  basic.statPanel(
    'Target: %(targetRatio).2f%%' % { targetRatio: slaTarget * 100.0 },
    '',
    thresholds(range).stepsFor('availability'),
    mappings=thresholds(range).mappingsFor('availability'),
    query=errorBudgetRatio(
      baseSelector {
        stage_group: groupSelectors,
      },
      range
    ),
    legendFormat='',
    unit='none',
    decimals='2'
  );

local timeRemainingTargetStatPanel(groupSelectors, range) =
  basic.statPanel(
    '%(range)s budget: %(budgetMinutes).0f minutes' % {
      budgetMinutes: (budgetSeconds(range) / 60.0),
      range: range,
    },
    '',
    thresholds(range).stepsFor('secondsRemaining'),
    mappings=thresholds(range).mappingsFor('secondsRemaining'),
    query=errorBudgetTimeRemaining(
      baseSelector {
        stage_group: groupSelectors,
      },
      range
    ),
    legendFormat='',
    unit='none',
    decimals='2'
  );

local timeRemainingStatPanel(groupSelectors, range) =
  basic.statPanel(
    '',
    'Budget remaining',
    thresholds(range).stepsFor('secondsRemaining'),
    query=errorBudgetTimeRemaining(
      baseSelector {
        stage_group: groupSelectors,
      },
      range
    ),
    legendFormat='',
    unit='s',
  );

local timeSpentStatPanel(groupSelectors, range) =
  basic.statPanel(
    '',
    'Budget spent',
    thresholds(range).stepsFor('secondsSpent'),
    query=errorBudgetTimeSpent(
      baseSelector {
        stage_group: groupSelectors,
      },
      range
    ),
    legendFormat='',
    unit='s',
  );

local timeSpentTargetStatPanel(groupSelectors, range) =
  basic.statPanel(
    'Target: Less than %(budgetMinutes).0f minutes in %(range)s' % {
      budgetMinutes: (budgetSeconds(range) / 60.0),
      range: range,
    },
    '',
    thresholds(range).stepsFor('secondsSpent'),
    mappings=thresholds(range).mappingsFor('secondsSpent'),
    query=errorBudgetTimeSpent(
      baseSelector {
        stage_group: groupSelectors,
      },
      range
    ),
    legendFormat='',
    unit='none',
    decimals='2'
  );

{
  availabilityStatPanel(groupSelectors, range):: availabilityStatPanel(groupSelectors, range),
  availabilityTargetStatPanel(groupSelectors, range):: availabilityTargetStatPanel(groupSelectors, range),
  timeSpentStatPanel(groupSelectors, range):: timeSpentStatPanel(groupSelectors, range),
  timeRemainingStatPanel(groupSelectors, range):: timeRemainingStatPanel(groupSelectors, range),
  timeRemainingTargetStatPanel(groupSelectors, range):: timeRemainingTargetStatPanel(groupSelectors, range),
  timeSpentTargetPanel(groupSelectors, range):: timeSpentTargetStatPanel(groupSelectors, range),
  timeSpentTargetStatPanel(groupSelectors, range):: timeSpentTargetStatPanel(groupSelectors, range),
  slaTarget: slaTarget,
  budgetSeconds(range):: budgetSeconds(range),
}
