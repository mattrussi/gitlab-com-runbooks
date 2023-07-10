local aggregations = import '../../libsonnet/promql/aggregations.libsonnet';
local errorBudgetUtils = import '../../libsonnet/stage-groups/error-budget/utils.libsonnet';
local errorBudget = import '../../libsonnet/stage-groups/error_budget.libsonnet';
local library = import 'gitlab-slis/library.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local prebuiltTemplates = import 'grafana/templates.libsonnet';
local selectors = import 'promql/selectors.libsonnet';


local baseSelector = {
  monitor: 'global',
};

local envSelector = {
  stage: '$stage',
  environment: '$environment',
};

local groupSelector = {
  product_stage: { re: '$product_stage' },
  stage_group: { re: '$stage_group' },
};

local componentSelector = {
  component: { re: '$component' },
};

local queries = errorBudget('$__range').queries;

local availabilityQuery = queries.errorBudgetRatio(baseSelector + envSelector + groupSelector + componentSelector);
local apdexQuery = queries.errorBudgetApdexRatio(baseSelector + envSelector + groupSelector + componentSelector);
local errorRatioQuery = queries.errorBudgetErrorRatio(baseSelector + envSelector + groupSelector + componentSelector);

local significantLabels = aggregations.join(
  std.flatMap(
    function(sli) sli.significantLabels,
    library.all
  ) + ['type']
);

local leftJoinStageGroup(query) =
  |||
    %(query)s
    * on (feature_category) group_left(stage_group) gitlab:feature_category:stage_group:mapping{%(groupSelector)s}
    or on () (%(query)s)
  ||| % {
    query: query,
    groupSelector: selectors.serializeHash(baseSelector + groupSelector),
  };

local operationsApdex =
  leftJoinStageGroup(
    |||
      clamp_max(
        sum by(%(labels)s) (
          sum_over_time({%(numeratorSelector)s}[$__range]) > 0
        )
        /
        sum by(%(labels)s) (
          sum_over_time({%(denominatorSelector)s}[$__range]) > 0
        )
      , 1
      )
    ||| % {
      labels: significantLabels,
      numeratorSelector: selectors.serializeHash(baseSelector + envSelector + {
        __name__: { re: 'application_sli_aggregation:($component):apdex:success:rate_1h' },
      }),
      denominatorSelector: selectors.serializeHash(baseSelector + envSelector + {
        __name__: { re: 'application_sli_aggregation:($component):apdex:weight:score_1h' },
      }),
    }

  );

local operations =
  leftJoinStageGroup(
    |||
      sum by(%(labels)s) (
        sum_over_time({%(baseSelector)s}[$__range])
      )
    ||| % {
      labels: significantLabels,
      baseSelector: selectors.serializeHash(baseSelector + envSelector + {
        __name__: { re: 'application_sli_aggregation:($component):ops:rate_1h' },
      }),
    }
  );

local operationsErrorRatio =
  leftJoinStageGroup(
    |||
      clamp_max(
        sum by(%(labels)s) (
          sum_over_time({%(numeratorSelector)s}[$__range])
        )
        /
        sum by(%(labels)s) (
          sum_over_time({%(denominatorSelector)s}[$__range])
        )
      , 1
      )
    ||| % {
      labels: significantLabels,
      numeratorSelector: selectors.serializeHash(baseSelector + envSelector + {
        __name__: { re: 'application_sli_aggregation:($component):error:rate_1h' },
      }),
      denominatorSelector: selectors.serializeHash(baseSelector + envSelector + {
        __name__: { re: 'application_sli_aggregation:($component):ops:rate_1h' },
      }),
      groupSelector: selectors.serializeHash(baseSelector + groupSelector),
    }
  );

local significantLabelsTable =
  basic.table(
    styles=null,
    queries=[
      errorBudgetUtils.rateToOperationCount(operations),
      operationsApdex,
      operationsErrorRatio,
    ],
    transformations=[
      {
        id: 'merge',
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'Value #A',
          renamePattern: 'operations',
        },
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'Value #B',
          renamePattern: 'apdex',
        },
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'Value #C',
          renamePattern: 'errors',
        },
      },
      {
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
            env: true,
          },
          indexByName: {
            endpoint_id: 1,
            feature_category: 2,
            stage_group: 3,
            request_urgency: 4,
            query_urgency: 5,
            search_level: 6,
            search_scope: 7,
            search_type: 8,
            document_type: 9,
            type: 10,
            operations: 11,
            apdex: 12,
            errors: 13,
          },
        },
      },
    ],
  ) + {
    options: {
      sortBy: [
        { displayName: 'operations', desc: true },
      ],
    },
    fieldConfig+: {
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'feature_category',
          },
          properties: [
            {
              id: 'custom.width',
              value: 300,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'stage_group',
          },
          properties: [
            {
              id: 'custom.width',
              value: 300,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'request_urgency',
          },
          properties: [
            {
              id: 'mappings',
              value: [
                {
                  type: 'value',
                  options: {
                    low: {
                      text: '🔴 low',
                    },
                    default: {
                      text: '🟠 default',
                    },
                    medium: {
                      text: '🟡 medium',
                    },
                    high: {
                      text: '🟢 high',
                    },
                  },
                },
              ],
            },
            {
              id: 'custom.width',
              value: 150,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'query_urgency',
          },
          properties: [
            {
              id: 'mappings',
              value: [
                {
                  type: 'value',
                  options: {
                    low: {
                      text: '🔴 low',
                    },
                    default: {
                      text: '🟠 default',
                    },
                    medium: {
                      text: '🟡 medium',
                    },
                    high: {
                      text: '🟢 high',
                    },
                  },
                },
              ],
            },
            {
              id: 'custom.width',
              value: 150,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'search_level',
          },
          properties: [
            {
              id: 'custom.width',
              value: 150,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'search_scope',
          },
          properties: [
            {
              id: 'custom.width',
              value: 150,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'search_type',
          },
          properties: [
            {
              id: 'custom.width',
              value: 150,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'type',
          },
          properties: [
            {
              id: 'custom.width',
              value: 120,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'operations',
          },
          properties: [
            {
              id: 'custom.width',
              value: 120,
            },
            {
              id: 'unit',
              value: 'locale',
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'apdex',
          },
          properties: [
            {
              id: 'custom.width',
              value: 120,
            },
            {
              id: 'unit',
              value: 'percentunit',
            },
            {
              id: 'decimals',
              value: 2,
            },
            {
              id: 'custom.cellOptions',
              value: {
                type: 'color-text',
              },
            },
            {
              id: 'color.mode',
              value: 'thresholds',
            },
            {
              id: 'thresholds',
              value: {
                steps: [
                  { color: 'red', value: null },
                  { color: 'green', value: 0.9995 },
                ],
              },
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'errors',
          },
          properties: [
            {
              id: 'custom.width',
              value: 120,
            },
            {
              id: 'unit',
              value: 'percentunit',
            },
            {
              id: 'decimals',
              value: 2,
            },
            {
              id: 'custom.cellOptions',
              value: {
                type: 'color-text',
              },
            },
            {
              id: 'color.mode',
              value: 'thresholds',
            },
            {
              id: 'thresholds',
              value: {
                steps: [
                  { color: 'green', value: null },
                  { color: 'red', value: 0.0005 },
                ],
              },
            },
          ],
        },
      ],
    },
  };

basic.dashboard(
  'Application SLI Violations',
  tags=[],
  time_from='now-7d/m',
  time_to='now/m',
).addTemplate(prebuiltTemplates.environment)
.addTemplate(prebuiltTemplates.stage)
.addTemplate(prebuiltTemplates.productStage())
.addTemplate(prebuiltTemplates.stageGroup())
.addTemplate(prebuiltTemplates.sli())
.addPanels(
  layout.grid(
    [
      basic.statPanel(
        title='',
        panelTitle='$component availability',
        query=availabilityQuery,
        decimals=2,
        unit='percentunit',
        color=[
          { color: 'red', value: null },
          { color: 'green', value: 0.9995 },
        ]
      ),
      basic.statPanel(
        title='',
        panelTitle='$component apdex',
        query=apdexQuery,
        decimals=2,
        unit='percentunit',
        color=[
          { color: 'red', value: null },
          { color: 'green', value: 0.9995 },
        ]
      ),
      basic.statPanel(
        title='',
        panelTitle='$component errors',
        query=errorRatioQuery,
        decimals=2,
        unit='percentunit',
        color=[
          { color: 'green', value: null },
          { color: 'red', value: 0.0005 },
        ]
      ),
    ], cols=3, rowHeight=5, startRow=100
  )
)
.addPanels(
  layout.rowGrid(
    '$component by significant labels',
    [significantLabelsTable],
    collapse=true,
    rowHeight=10,
    startRow=200,
  )
)
.trailer()
