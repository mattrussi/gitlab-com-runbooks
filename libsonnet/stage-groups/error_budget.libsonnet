local basic = import 'grafana/basic.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local durationParser = import 'utils/duration-parser.libsonnet';
local slaTarget = (import '../../metrics-catalog/metrics-config.libsonnet').slaTarget;

local baseSelector = {
  stage: '$stage',
  environment: '$environment',
  monitor: 'global',
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
          ) or vector(0)
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
        ) or vector(0)
      ),
    1)
  ||| % {
    selectorHash: selectors.serializeHash(groupSelectors),
    range: range,
  };

local errorBudgetSpentTime(selectors, range) =
  |||
    (
      1 - %(ratioQuery)s
    ) * %(rangeInSeconds)i
  ||| % {
    ratioQuery: errorBudgetRatio(selectors, range),
    rangeInSeconds: durationParser.toSeconds(range),
  };

local availabilityStatPanel(groupSelectors, range) =
  basic.statPanel(
    '',
    'Availability',
    [
      {
        color: 'red',
        value: 0.0,
      },
      {
        color: 'yellow',
        value: slaTarget - 0.0001,
      },
      {
        color: 'green',
        value: slaTarget,
      },
    ],
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

local timeSpentStatPanel(groupSelectors, range) =
  basic.statPanel(
    '',
    'Budget Spent',
    [
      {
        color: 'green',
        value: 0,
      },
      {
        color: 'yellow',
        value: (1 - slaTarget) * durationParser.toSeconds(range),
      },
      {
        color: 'red',
        value: (1 - slaTarget + 0.0001) * durationParser.toSeconds(range),
      },
    ],
    query=errorBudgetSpentTime(
      baseSelector {
        stage_group: groupSelectors,
      },
      range
    ),
    legendFormat='',
    unit='s',
  );

{
  availabilityStatPanel(groupSelectors, range):: availabilityStatPanel(groupSelectors, range),
  timeSpentStatPanel(groupSelectors, range):: timeSpentStatPanel(groupSelectors, range),
  slaTarget: slaTarget,
}
