local sidekiqHelpers = import '../../../metrics-catalog/services/lib/sidekiq-helpers.libsonnet';
local utils = import './utils.libsonnet';
local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local durationParser = import 'utils/duration-parser.libsonnet';
local strings = import 'utils/strings.libsonnet';

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
  local mapping(color, from, to, text, index) = {
    type: 'range',
    options: {
      from: from,
      to: to,
      result: {
        color: color,
        index: index,
        text: text,
      },
    },
  };
  local mappings(type) =
    std.mapWithIndex(
      function(index, definition) mapping(definition.color, definition[type].from, definition[type].to, definition.text, index),
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

local explanationPanel(slaTarget, range, group) =
  basic.text(
    title='Info',
    mode='markdown',
    content=|||
      ### [Error budget](https://about.gitlab.com/handbook/engineering/error-budgets/)

      These error budget panels show an aggregate of SLIs across all components.
      However, not all components have been implemented yet.

      The [handbook](https://about.gitlab.com/handbook/engineering/error-budgets/)
      explains how these budgets are used.

      Read more about how the error budgets are calculated in the
      [stage group dashboard documentation](https://docs.gitlab.com/ee/development/stage_group_dashboards.html#error-budget).

      The error budget is compared to our SLO of %(slaTarget)s and is always in
      a range of 28 days from the selected end date in Grafana.

      ### Availability

      The availability shows the percentage of operations labeled with one of the
      categories owned by %(group)s with satisfactory completion.

      ### Budget remaining

      The error budget in minutes is calculated based on the %(slaTarget)s.
      There are 40320 minutes in 28 days, we allow %(budgetRatio)s of failures, which
      means the budget in minutes is %(budgetMinutes)s minutes.

      The budget remaining shows how many minutes have not been spent in the
      past 28 days.

      ### Minutes spent

      This shows the total minutes spent over the past 28 days.

      For example, if there were 403200 (28 * 24 * 60) operations in 28 days.
      This would be 1 every minute. If 10 of those were unsatisfactory, that
      would mean 10 minutes of the budget were spent.
    ||| % {
      slaTarget: '%.2f%%' % (slaTarget * 100.0),
      budgetRatio: '%.2f%%' % ((1 - slaTarget) * 100.0),
      budgetMinutes: '%i' % (utils.budgetSeconds(slaTarget, range) / 60),
      group: group,
    },
  );

local localUnitOverride(fieldName) = {
  matcher: { id: 'byName', options: fieldName },
  properties: [{
    id: 'unit',
    value: 'locale',
  }],
};

// We're calculating an absolute number of failures from a failure rate
// this means we don't have an exact precision, but only a request per second
// number that we turn into an absolute number. To display a number of requests
// over multiple days, the decimals don't matter anymore, so we're rounding them
// up using `ceil`.
//
// The per-second-rates are sampled every minute, we assume that we continue
// to receive the same number of requests per second until the next sample.
// So we multiply the rate by the number of samples we don't have.
// For example: the last sample said we were processing 2RPS, next time we'll
// take a sample will be in 60s, so in that time we assume to process
// 60 * 2 = 120 requests.
// https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1123
local rateToOperationCount(query) =
  |||
    ceil(
      (
        %(query)s
      ) * 60
    )
  ||| % {
    query: strings.indent(strings.chomp(query), 4),
  };

local violationRatePanel(queries, group) =
  local selector = baseSelector {
    stage_group: group,
  };
  local aggregationLabels = ['component', 'violation_type', 'type'];
  basic.table(
    title='Budget failures',
    description='Number of failures contributing to the budget send per component and type ',
    styles=null,  // https://github.com/grafana/grafonnet-lib/issues/240
    queries=[
      rateToOperationCount(queries.errorBudgetViolationRate(selector, aggregationLabels)),
      rateToOperationCount(queries.errorBudgetOperationRate(selector, aggregationLabels)),
    ],
    transformations=[
      {
        id: 'merge',
      },
      {
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
          },
          indexByName: {
            violation_type: 0,
            type: 1,
            component: 2,
            'Value #A': 3,
            'Value #B': 4,
          },
          renameByName: {
            'Value #A': 'failures past 28 days',
            'Value #B': 'measurements past 28 days',

          },
        },
      },
    ],
  ) + {
    options: {
      sortBy: [{
        displayName: 'failures past 28 days',
        desc: true,
      }],
    },
    fieldConfig+: {
      overrides+: [
        {
          matcher: { id: 'byName', options: 'type' },
          properties: [{
            id: 'links',
            value: [{
              targetBlank: true,
              title: '${__value.text} overview: See ${__data.fields.component} SLI for details',
              url: 'https://dashboards.gitlab.net/d/${__value.text}-main',
            }],
          }],
        },
      ] + [
        localUnitOverride(fieldName)
        for fieldName in ['failures past 28 days', 'measurements past 28 days']
      ],
    },
  };

local violationRateExplanation =
  basic.text(
    title='Info',
    mode='markdown',
    content=|||
      This table shows the failures that contribute to the spend of the error budget.
      Fixing the top item in this table will have the biggest impact on the
      budget spend.

      A failure is one of 2 types:

      - **error**: An operation that failed: 500 response, failed background job.
      - **apdex**: This means an operation that succeeded, but did not perform within the set threshold.

      See the [developer documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/stage_group_dashboards.md#error-budget)
      to learn more about this.

      The component refers to the component in our stack where the violation occurred.
      The most common ones are:

      - **puma**: This component signifies requests handled by rails
      - **sidekiq_execution**: This component signifies background jobs executed by Sidekiq

      To find the endpoint that is attributing to the budget spend and a violation type
      we can use the logs over a 7 day range. Links for puma and sidekiq are available on the right.
      These logs list the endpoints that had the most violations over the past 7 days.

      The "Other" row is the sum of all the other violations excluding the top ones
      that are listed.
    |||,
  );

local sidekiqDurationThresholdByFilter =
  local knownDurationThresholds = std.map(
    function(sloName)
      sidekiqHelpers.slos[sloName].executionDurationSeconds,
    std.objectFields(sidekiqHelpers.slos)
  );
  local thresholds = {
    'json.shard: "urgent"': sidekiqHelpers.slos.urgent.executionDurationSeconds,
    'not json.shard: "urgent"': sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,
  };
  local definedThresholds = std.set(std.sort(std.objectValues(thresholds)));
  local knownThresholds = std.set(std.sort(knownDurationThresholds));
  if std.assertEqual(definedThresholds, knownThresholds) then
    thresholds;

local sidekiqDurationTableFilters = std.map(
  function(filter)
    local duration = sidekiqDurationThresholdByFilter[filter];
    {
      label: 'Jobs exceeding %is' % duration,
      input: {
        language: 'kuery',
        query: '%(filter)s AND json.duration_s > %(duration)i' % {
          filter: filter,
          duration: duration,
        },
      },
    },
  std.objectFields(sidekiqDurationThresholdByFilter),
);
local logLinks(featureCategories) =
  local featureCategoryFilters = elasticsearchLinks.matchers({
    'json.meta.feature_category': featureCategories,
  });
  local timeFrame = elasticsearchLinks.timeRange('now-7d', 'now');

  local pumaSplitColumns = ['json.meta.caller_id.keyword'];
  local pumaApdexTable = elasticsearchLinks.buildElasticTableCountVizURL(
    'rails',
    featureCategoryFilters,
    splitSeries=pumaSplitColumns,
    timeRange=timeFrame,
    extraAggs=[
      {
        enabled: true,
        id: '3',
        params: {
          customLabel: 'Operations over threshold (1s)',
          field: 'json.duration_s',
          json: '{"script": "doc[\'json.duration_s\'].value >= 1 ? 1 : 0"}',
        },
        schema: 'metric',
        type: 'sum',
      },
      {
        enabled: true,
        id: '4',
        params: {
          customLabel: 'Operations over error budget threshold (5s)',
          field: 'json.duration_s',
          json: '{"script": "doc[\'json.duration_s\'].value >= 5 ? 1 : 0"}',
        },
        schema: 'metric',
        type: 'sum',
      },
    ],
    orderById='3',
  );
  local pumaErrorsTable = elasticsearchLinks.buildElasticTableFailureCountVizURL(
    'rails', featureCategoryFilters, splitSeries=pumaSplitColumns, timeRange=timeFrame
  );

  local sidekiqSplitColumns = ['json.class.keyword'];

  local sidekiqErrorsTable = elasticsearchLinks.buildElasticTableFailureCountVizURL(
    'sidekiq', featureCategoryFilters, splitSeries=sidekiqSplitColumns, timeRange=timeFrame
  );

  local urgencySplit = {
    type: 'filters',
    schema: 'split',
    params: {
      filters: sidekiqDurationTableFilters,
    },
  };
  local doneFilter = elasticsearchLinks.matchers({
    'json.job_status': 'done',
  });

  local sidekiqApdexTables = elasticsearchLinks.buildElasticTableCountVizURL(
    'sidekiq', featureCategoryFilters + doneFilter, splitSeries=[urgencySplit] + sidekiqSplitColumns, timeRange=timeFrame
  );

  basic.text(
    title='Failure log links',
    mode='markdown',
    content=|||
      ##### [Puma Apdex](%(pumaApdexLink)s): slow requests

      This shows the number of requests exceeding the request duration thresholds
      per endpoint over the past 7 days.

      This shows all requests exceeding 1s and 5s durations. We will make this
      take the configured [request urgency](%(requestUrgencyLink)s) into account in
      [this issue](%(scalability1478)s).

      ##### [Puma Errors](%(pumaErrorsLink)s): failing requests

      This shows the number of Rails requests that failed per endpoint over
      the past 7 days.

      ##### [Sidekiq Execution Apdex](%(sidekiqApdexLink)s): slow jobs

      This shows the number of jobs per worker that took longer than their threshold to
      execute over the past 7 days.
      For urgent jobs the threshold is %(sidekiqUrgentThreshold)is, this is the table on the left.
      For other jobs the threshold is %(sidekiqNormalThreshold)is, this is the table on the right.

      ##### [Sidekiq Execution Errors](%(sidekiqErrorsLink)s): failing jobs

      This shows the number of jobs per worker that failed over the past 7 days.
      This includes retries: if a job with a was retried 3 times, before exhausting
      its retries, this counts as 3 failures towards the budget.
    ||| % {
      pumaApdexLink: pumaApdexTable,
      requestUrgencyLink: 'https://docs.gitlab.com/ee/development/application_slis/rails_request_apdex.html#adjusting-request-urgency',
      scalability1478: 'https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1478',
      pumaErrorsLink: pumaErrorsTable,
      sidekiqErrorsLink: sidekiqErrorsTable,
      sidekiqApdexLink: sidekiqApdexTables,
      sidekiqUrgentThreshold: sidekiqHelpers.slos.urgent.executionDurationSeconds,
      sidekiqNormalThreshold: sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,
    },
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
    explanationPanel(group)::
      explanationPanel(slaTarget, range, group),
    violationRatePanel(group)::
      violationRatePanel(queries, group),
    violationRateExplanation:: violationRateExplanation,
    logLinks:: logLinks,
  },
}
