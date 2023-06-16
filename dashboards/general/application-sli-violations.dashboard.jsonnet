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
  )
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
          sum_over_time(application_sli_aggregation:$component:apdex:success:rate_1h{%(baseSelector)s}[$__range]) > 0
        )
        /
        sum by(%(labels)s) (
          sum_over_time(application_sli_aggregation:$component:apdex:weight:score_1h{%(baseSelector)s}[$__range]) > 0
        )
      , 1
      )
    ||| % {
      labels: significantLabels,
      baseSelector: selectors.serializeHash(baseSelector + envSelector),
    }

  );

local operations =
  leftJoinStageGroup(
    |||
      sum by(%(labels)s) (
        sum_over_time(application_sli_aggregation:$component:ops:rate_1h{%(baseSelector)s}[$__range])
      )
    ||| % {
      labels: significantLabels,
      baseSelector: selectors.serializeHash(baseSelector + envSelector),
    }
  );

local operationsErrorRatio =
  leftJoinStageGroup(
    |||
      clamp_max(
        sum by(%(labels)s) (
          sum_over_time(application_sli_aggregation:$component:error:rate_1h{%(baseSelector)s}[$__range])
        )
        /
        sum by(%(labels)s) (
          sum_over_time(application_sli_aggregation:$component:ops:rate_1h{%(baseSelector)s}[$__range])
        )
      , 1
      )
    ||| % {
      labels: significantLabels,
      baseSelector: selectors.serializeHash(baseSelector + envSelector),
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
          renamePattern: 'Operations',
        },
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'Value #B',
          renamePattern: 'Apdex',
        },
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'Value #C',
          renamePattern: 'Errors',
        },
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'feature_category',
          renamePattern: 'Category',
        },
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'stage_group',
          renamePattern: 'Stage Group',
        },
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'request_urgency',
          renamePattern: 'Urgency',
        },
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'query_urgency',
          renamePattern: 'Urgency',
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
            Category: 2,
            'Stage Group': 3,
            Urgency: 4,
            search_level: 5,
            search_scope: 6,
            search_type: 7,
            document_type: 8,
            Operations: 9,
            Apdex: 10,
            Errors: 11,
          },
        },
      },
    ],
  ) + {
    options: {
      sortBy: [
        { displayName: 'Operations', desc: true },
      ],
    },
    fieldConfig+: {
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'Category',
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
            options: 'Stage Group',
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
            options: 'Urgency',
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
              value: 120,
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
            options: 'Operations',
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
            options: 'Apdex',
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
            options: 'Errors',
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
