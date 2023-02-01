local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local prebuiltTemplates = import 'grafana/templates.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local baseSelector = {
  stage: '$stage',
  environment: '$environment',
  monitor: 'global',
};

local groupSelector = {
  product_stage: { re: '$product_stage' },
  stage_group: { re: '$stage_group' },
};

local mappingSelector = {
  monitor: 'global',
};

local knownEndpointsSelector = { endpoint_id: { ne: 'unknown' } };
local knownUrgencies = ['high', 'medium', 'default', 'low'];

local percentageOfTrafficByUrgency(urgencySelector) =
  |||
    (
      sum by (request_urgency) (
        sum by (request_urgency, feature_category)(
          sum_over_time(application_sli_aggregation:rails_request:apdex:weight:score_1h{%(numeratorSelector)s}[6h]) > 0
        ) * on (feature_category) group by (stage_group,product_stage,feature_category) (gitlab:feature_category:stage_group:mapping{%(stageGroupSelector)s})
      )
      / ignoring(request_urgency) group_left() sum(
        sum by (feature_category)(
          sum_over_time(application_sli_aggregation:rails_request:apdex:weight:score_1h{%(denominatorSelector)s}[6h]) > 0
        ) * on (feature_category) group by (stage_group,product_stage,feature_category) (gitlab:feature_category:stage_group:mapping{%(stageGroupSelector)s})
      )
    )
  ||| % {
    numeratorSelector: selectors.serializeHash(baseSelector + knownEndpointsSelector + urgencySelector),
    denominatorSelector: selectors.serializeHash(baseSelector + knownEndpointsSelector),
    stageGroupSelector: selectors.serializeHash(groupSelector + mappingSelector),
  };

local numberOfEndpointsPromQL(selector) = |||
  count(
    count by (endpoint_id, feature_category) (
      count_over_time(application_sli_aggregation:rails_request:apdex:weight:score_1h{%(selector)s}[6h]) > 0
    ) * on (feature_category) group_left() group by (stage_group,product_stage,feature_category) (gitlab:feature_category:stage_group:mapping{%(stageGroupSelector)s})
  )
||| % {
  selector: selectors.serializeHash(baseSelector + knownEndpointsSelector + selector),
  stageGroupSelector: selectors.serializeHash(groupSelector + mappingSelector),
};

local topEndpoints(selector) = |||
  sort_desc(
    sum by (feature_category, endpoint_id)(
      sum_over_time(application_sli_aggregation:rails_request:apdex:weight:score_1h{%(selector)s}[6h])
    ) * on (feature_category) group_left(stage_group, product_stage) group by (stage_group,product_stage,feature_category) (gitlab:feature_category:stage_group:mapping{%(stageGroupSelector)s})
  )
||| % {
  selector: selectors.serializeHash(baseSelector + knownEndpointsSelector + selector),
  stageGroupSelector: selectors.serializeHash(groupSelector + mappingSelector),
};

local trafficForUrgency(urgency) =
  basic.statPanel(
    '',
    '%s urgency requests' % [urgency],
    'blue',
    percentageOfTrafficByUrgency({ request_urgency: urgency }),
    '{{ urgency }}',
    unit='percentunit',
  );

local endpointCountForUrgency(urgency) =
  basic.statPanel(
    '%s urgency endpoints' % [urgency],
    '',
    'blue',
    numberOfEndpointsPromQL({ request_urgency: urgency }),
    '',
  );

local endpointsForUrgency(urgency) =
  basic.table(
    title='%s urgency endpoints ordered by request rate' % [urgency],
    styles=null,
    queries=[topEndpoints({ request_urgency: urgency })],
    transformations=[
      {
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
            feature_category: true,
            product_stage: true,
          },
          indexByName: {
            stage_group: 1,
            endpoint_id: 2,
            Value: 3,
          },
          renameByName: {
            stage_group: 'Group',
            Value: 'Rate',
          },
        },
      },
    ],
  ) {
    fieldConfig+: {
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'Stage',
          },
          properties: [{
            id: 'custom.width',
            value: 80,
          }],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Group',
          },
          properties: [{
            id: 'custom.width',
            value: 130,
          }],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Rate',
          },
          properties: [{
            id: 'custom.width',
            value: 80,
          }],
        },
      ],
    },
  };

local trafficForUrgencyPanels(urgency) =
  [
    trafficForUrgency(urgency),
    endpointCountForUrgency(urgency),
  ];


local endpointsSortedByTraffic =
  |||
    sort_desc(
      sum by(endpoint_id, request_urgency, feature_category, env) (
        sum_over_time(application_sli_aggregation:rails_request:apdex:weight:score_1h{%(numeratorSelector)s}[$__range]) > 0
      )
      / ignoring(endpoint_id, feature_category, request_urgency) group_left
      sum by(env) (
        sum_over_time(application_sli_aggregation:rails_request:apdex:weight:score_1h{%(numeratorSelector)s}[$__range]) > 0
      )
    ) * on(feature_category) group_left(stage_group, product_stage)
    sum by(feature_category, stage_group, product_stage) (
      gitlab:feature_category:stage_group:mapping{%(stageGroupSelector)s}
    )
  ||| % {
    numeratorSelector: selectors.serializeHash(baseSelector),
    stageGroupSelector: selectors.serializeHash(groupSelector + mappingSelector),
  }
;

local endpointsSortedByTrafficTable =
  basic.table(
    title='Endpoints by traffic %',
    styles=null,
    query=endpointsSortedByTraffic,
    transformations=[
      {
        id: 'renameByRegex',
        options: {
          regex: 'Value',
          renamePattern: 'Traffic %',
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
          regex: 'stage_group',
          renamePattern: 'Stage Group',
        },
      },
      {
        id: 'renameByRegex',
        options: {
          regex: 'product_stage',
          renamePattern: 'Product Stage',
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
            'Product Stage': 3,
            Urgency: 4,
            'Traffic %': 5,
          },
        },
      },
    ],
  ) {
    fieldConfig+: {
      overrides: [
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
              value: 160,
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
              value: 360,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Product Stage',
          },
          properties: [
            {
              id: 'custom.width',
              value: 200,
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Traffic %',
          },
          properties: [
            {
              id: 'custom.width',
              value: 80,
            },
            {
              id: 'unit',
              decimals: 3,
              value: 'percentunit',
            },
          ],
        },
      ],
    },
  };

basic.dashboard(
  'Rails Endpoints Traffic Share',
  tags=[],
  time_from='now-2d/m',
  time_to='now/m',
).addTemplate(prebuiltTemplates.environment)
.addTemplate(prebuiltTemplates.stage)
.addTemplate(prebuiltTemplates.productStage())
.addTemplate(prebuiltTemplates.stageGroup())
.addPanels(
  layout.splitColumnGrid(
    std.map(trafficForUrgencyPanels, knownUrgencies),
    title='Traffic by urgency (over the last 6h)',
    startRow=0,
    cellHeights=[4, 2],
  )
)
.addPanels(
  layout.rowGrid(
    'Endpoints by urgency (over the last 6h)',
    std.map(endpointsForUrgency, knownUrgencies),
    collapse=true,
    startRow=100,
  )
)
.addPanels(
  layout.rowGrid(
    'Endpoints by traffic %',
    [endpointsSortedByTrafficTable],
    collapse=true,
    rowHeight=10,
    startRow=400,
  )
)
.trailer()
