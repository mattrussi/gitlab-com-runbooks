local errorBudgetUtils = import '../../libsonnet/stage-groups/error-budget/utils.libsonnet';
local errorBudget = import '../../libsonnet/stage-groups/error_budget.libsonnet';
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
  stage_group: { re: '$stage_group' },
};

local componentSelector = {
  component: 'rails_request',
};

local queries = errorBudget('$__range').queries;

local availabilityQuery = queries.errorBudgetRatio(baseSelector + envSelector + groupSelector + componentSelector);
local apdexQuery = queries.errorBudgetApdexRatio(baseSelector + envSelector + groupSelector + componentSelector);
local errorRatioQuery = queries.errorBudgetErrorRatio(baseSelector + envSelector + groupSelector + componentSelector);

local endpointsApdex =
  |||
    clamp_max(
      sum by(endpoint_id, feature_category, request_urgency) (
        (sum_over_time(application_sli_aggregation:rails_request:apdex:success:rate_1h{%(baseSelector)s}[$__range]) > 0)
        * on (feature_category) group_left(stage_group) gitlab:feature_category:stage_group:mapping{%(groupSelector)s}
      )
      /
      sum by(endpoint_id, feature_category, request_urgency) (
        (sum_over_time(application_sli_aggregation:rails_request:apdex:weight:score_1h{%(baseSelector)s}[$__range]) > 0)
        * on (feature_category) group_left(stage_group) gitlab:feature_category:stage_group:mapping{%(groupSelector)s}
      )
    , 1
    )
  ||| % {
    baseSelector: selectors.serializeHash(baseSelector + envSelector),
    groupSelector: selectors.serializeHash(baseSelector + groupSelector),
  }
;

local endpointsRequests =
  |||
    sum by(endpoint_id, feature_category, request_urgency) (
      sum_over_time(application_sli_aggregation:rails_request:ops:rate_1h{%(baseSelector)s}[$__range])
    )
    * on (feature_category) group_left(stage_group) gitlab:feature_category:stage_group:mapping{%(groupSelector)s}
  ||| % {
    baseSelector: selectors.serializeHash(baseSelector + envSelector),
    groupSelector: selectors.serializeHash(baseSelector + groupSelector),
  }
;

local endpointsErrorRatio =
  |||
    clamp_max(
      sum by(endpoint_id, feature_category, request_urgency) (
        sum_over_time(application_sli_aggregation:rails_request:error:rate_1h{%(baseSelector)s}[$__range])
        * on (feature_category) group_left(stage_group) gitlab:feature_category:stage_group:mapping{%(groupSelector)s}
      )
      /
      sum by(endpoint_id, feature_category, request_urgency) (
        sum_over_time(application_sli_aggregation:rails_request:ops:rate_1h{%(baseSelector)s}[$__range])
        * on (feature_category) group_left(stage_group) gitlab:feature_category:stage_group:mapping{%(groupSelector)s}
      )
    , 1
    )
  ||| % {
    baseSelector: selectors.serializeHash(baseSelector + envSelector),
    groupSelector: selectors.serializeHash(baseSelector + groupSelector),
  }
;

local endpointsTable =
  basic.table(
    title='Endpoints',
    styles=null,
    queries=[
      errorBudgetUtils.rateToOperationCount(endpointsRequests),
      endpointsApdex,
      endpointsErrorRatio,
    ],
    transformations=[
      {
        id: 'merge',
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'Value #A',
          renamePattern: 'Requests',
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
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
            env: true,
            feature_category: true,
          },
          indexByName: {
            endpoint_id: 1,
            'Stage Group': 2,
            Urgency: 3,
            Requests: 4,
            Apdex: 5,
            Errors: 6,
          },
        },
      },
    ],
  ) + {
    options: {
      sortBy: [
        { displayName: 'Requests', desc: true },
      ],
    },
    fieldConfig+: {
      overrides: [
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
            options: 'Requests',
          },
          properties: [
            {
              id: 'custom.width',
              value: 100,
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
  'Rails Endpoints Violations',
  tags=[],
  time_from='now-7d/m',
  time_to='now/m',
).addTemplate(prebuiltTemplates.environment)
.addTemplate(prebuiltTemplates.stage)
.addTemplate(prebuiltTemplates.stageGroup())
.addPanels(
  layout.grid(
    [
      basic.statPanel(
        title='',
        panelTitle='Rails Request Availability',
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
        panelTitle='Rails Request Apdex',
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
        panelTitle='Rails Request Errors',
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
    'Apdex by endpoints',
    [endpointsTable],
    collapse=true,
    rowHeight=10,
    startRow=200,
  )
)
.trailer()
