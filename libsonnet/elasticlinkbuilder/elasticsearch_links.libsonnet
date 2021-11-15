local rison = import 'rison.libsonnet';

local grafanaTimeFrom = '${__from:date:iso}';
local grafanaTimeTo = '${__to:date:iso}';

local elasticTimeRange(from, to) =
  "(time:(from:'%(from)s',to:'%(to)s'))" % { from: from, to: to };

local grafanaTimeRange = elasticTimeRange(grafanaTimeFrom, grafanaTimeTo);

// Builds an ElasticSearch match filter clause
local matchFilter(field, value) =
  {
    query: {
      match: {
        [field]: {
          query: value,
          type: 'phrase',
        },
      },

    },
  };

local matchInFilter(field, possibleValues) =
  {
    query: {
      bool: {
        should: [{ match_phrase: { [field]: possibleValue } } for possibleValue in possibleValues],
        minimum_should_match: 1,
      },
    },
  };

// Builds an ElasticSearch range filter clause
local rangeFilter(field, gteValue, lteValue) =
  {
    query: {
      range: {
        [field]: {
          [if gteValue != null then 'gte']: gteValue,
          [if lteValue != null then 'lte']: lteValue,
        },
      },
    },
  };

local existsFilter(field) =
  {
    exists: {
      field: field,
    },
  };

local mustNot(filter) =
  filter {
    meta+: {
      negate: true,
    },
  };

local matchObject(fieldName, matchInfo) =
  local gte = if std.objectHas(matchInfo, 'gte') then matchInfo.gte else null;
  local lte = if std.objectHas(matchInfo, 'lte') then matchInfo.lte else null;
  local values = std.prune([gte, lte]);

  if std.length(values) > 0 then
    rangeFilter(fieldName, gte, lte)
  else
    std.assertEqual(false, { __message__: 'Only gte and lte fields are supported but not in [%s]' % std.join(', ', std.objectFields(matchInfo)) });

local matcher(fieldName, matchInfo) =
  if std.isString(matchInfo) then
    matchFilter(fieldName, matchInfo)
  else if std.isArray(matchInfo) then
    matchInFilter(fieldName, matchInfo)
  else if std.isObject(matchInfo) then
    matchObject(fieldName, matchInfo);

local matchers(matches) =
  [
    matcher(k, matches[k])
    for k in std.objectFields(matches)
  ];

local statusCode(field) =
  [rangeFilter(field, gteValue=500, lteValue=null)];

local indexDefaults = {
  defaultFilters: [],
  kibanaEndpoint: 'https://log.gprd.gitlab.net/app/kibana',
  prometheusLabelMappings: {},
};

local globalState(str) =
  if str == null || str == '' then
    ''
  else
    '&_g=' + str;

// These are default prometheus label mappings, for mapping
// between prometheus labels and their equivalent ELK fields
// We know that these fields exist on most of our structured logs
// so we can safely map from the given labels to the fields in all cases
local defaultPrometheusLabelMappings = {
  type: 'json.type',
  stage: 'json.stage',
};

local indexCatalog = {
  // Improve these logs when https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/11221 is addressed
  camoproxy: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: 'AWz5hIoSGphUgZwzAG7q',
    defaultColumns: ['json.hostname', 'json.camoproxy_message', 'json.camoproxy_err'],
    defaultSeriesSplitField: 'json.hostname.keyword',
    failureFilter: [existsFilter('json.camoproxy_err')],
    //defaultLatencyField: 'json.grpc.time_ms',
    //latencyFieldUnitMultiplier: 1000,
  },

  gitaly: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AW5F1OHTiGcMMNRn84Di',
    defaultColumns: ['json.hostname', 'json.grpc.method', 'json.grpc.request.glProjectPath', 'json.grpc.code', 'json.grpc.time_ms'],
    defaultSeriesSplitField: 'json.grpc.method.keyword',
    failureFilter: [mustNot(matchFilter('json.grpc.code', 'OK')), existsFilter('json.grpc.code')],
    slowRequestFilter: [matchFilter('json.msg', 'unary')],
    defaultLatencyField: 'json.grpc.time_ms',
    prometheusLabelMappings+: {
      fqdn: 'json.fqdn',
    },
    latencyFieldUnitMultiplier: 1000,
  },

  kas: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '78f49290-709e-11eb-b821-df2c3b5b1510',
    defaultColumns: ['json.msg', 'json.project_id', 'json.commit_id', 'json.number_of_files', 'json.grpc.time_ms'],
    defaultSeriesSplitField: 'json.grpc.method.keyword',
    failureFilter: [existsFilter('json.error')],
    //defaultLatencyField: '',
    //latencyFieldUnitMultiplier: 1000,
  },

  monitoring_ops: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: 'pubsub-monitoring-inf-ops',
    defaultColumns: ['json.hostname', 'json.msg', 'json.level'],
    defaultSeriesSplitField: 'json.hostname.keyword',
    failureFilter: [matchFilter('json.level', 'error')],
    kibanaEndpoint: 'https://nonprod-log.gitlab.net/app/kibana',
  },

  monitoring_gprd: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: 'AW5ZoH2ddtvLTaJbch2P',
    defaultColumns: ['json.hostname', 'json.msg', 'json.level'],
    defaultSeriesSplitField: 'json.hostname.keyword',
    failureFilter: [matchFilter('json.level', 'error')],
  },

  pages: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWRaEscWMdvjVyaYlI-L',
    defaultColumns: ['json.hostname', 'json.pages_domain', 'json.host', 'json.pages_host', 'json.path', 'json.remote_ip', 'json.duration_ms'],
    defaultSeriesSplitField: 'json.pages_host.keyword',
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  postgres: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: '97f04200-024b-11eb-81e5-155ba78758d4',
    defaultColumns: ['json.hostname', 'json.endpoint_id', 'json.error_severity', 'json.message', 'json.session_start_time', 'json.sql_state_code', 'json.duration_s', 'json.sql'],
    defaultSeriesSplitField: 'json.fingerprint.keyword',
    failureFilter: [mustNot(matchFilter('json.sql_state_code', '00000')), existsFilter('json.sql_state_code')],  // SQL Codes reference: https://www.postgresql.org/docs/9.4/errcodes-appendix.html
    defaultLatencyField: 'json.duration_s',  // Only makes sense in the context of slowlog entries
    latencyFieldUnitMultiplier: 1,
  },

  postgres_pgbouncer: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '97f04200-024b-11eb-81e5-155ba78758d4',
    defaultColumns: ['json.hostname', 'json.pg_message'],
    defaultSeriesSplitField: 'json.hostname.keyword',
  },

  praefect: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AW98WAQvqthdGjPJ8jTY',
    defaultColumns: ['json.hostname', 'json.virtual_storage', 'json.grpc.method', 'json.relative_path', 'json.grpc.code', 'json.grpc.time_ms'],
    defaultSeriesSplitField: 'json.grpc.method.keyword',
    failureFilter: [mustNot(matchFilter('json.grpc.code', 'OK')), existsFilter('json.grpc.code')],
    slowRequestFilter: [matchFilter('json.msg', 'unary')],
    defaultLatencyField: 'json.grpc.time_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  pvs: indexDefaults {
    timestamp: 'json.timestamp',
    indexPattern: '4858f3a0-a312-11eb-966b-2361593353f9',
    defaultColumns: ['json.jsonPayload.mode', 'json.jsonPayload.validation_status', 'json.jsonPayload.project_id', 'json.jsonPayload.correation_id', 'json.jsonPayload.msg'],
    defaultSeriesSplitField: 'json.jsonPayload.validation_status.keyword',
    failureFilter: statusCode('json.jsonPayload.status_code'),
    defaultLatencyField: 'json.jsonPayload.duration_ms',
  },

  rails: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '7092c4e2-4eb5-46f2-8305-a7da2edad090',
    defaultColumns: ['json.method', 'json.status', 'json.controller', 'json.action', 'json.path', 'json.duration_s'],
    defaultSeriesSplitField: 'json.controller.keyword',
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_s',
    latencyFieldUnitMultiplier: 1,
  },

  rails_api: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '7092c4e2-4eb5-46f2-8305-a7da2edad090',
    defaultColumns: ['json.method', 'json.status', 'json.route', 'json.path', 'json.duration_s'],
    defaultSeriesSplitField: 'json.route.keyword',
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_s',
    latencyFieldUnitMultiplier: 1,
  },

  redis: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWSQX_Vf93rHTYrsexmk',
    defaultColumns: ['json.hostname', 'json.redis_message'],
    defaultSeriesSplitField: 'json.hostname.keyword',
  },

  redis_slowlog: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWSQX_Vf93rHTYrsexmk',
    defaultColumns: ['json.hostname', 'json.command', 'json.exec_time_s'],
    defaultSeriesSplitField: 'json.hostname.keyword',
    defaultFilters: [matchFilter('json.tag', 'redis.slowlog')],
    defaultLatencyField: 'json.exec_time_s',
    latencyFieldUnitMultiplier: 1,  // Redis uses `µs`, but the field is in `s`
  },

  registry: indexDefaults {
    timestamp: 'json.time',
    indexPattern: '97ce8e90-63ad-11ea-8617-2347010d3aab',
    defaultColumns: ['json.remote_ip', 'json.duration_ms', 'json.code', 'json.msg', 'json.status', 'json.error', 'json.method', 'json.uri'],
    defaultSeriesSplitField: 'json.remote_ip',
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  runners: indexDefaults {
    timestamp: '@timestamp',
    indexPattern: 'pubsub-runner-inf-gprd',
    defaultColumns: ['json.operation', 'json.job', 'json.operation', 'json.repo_url', 'json.project', 'json.msg'],
    defaultSeriesSplitField: 'json.repo_url.keyword',
    failureFilter: [matchFilter('json.msg', 'Job failed (system failure)')],
    defaultLatencyField: 'json.duration',
    latencyFieldUnitMultiplier: 1000000000,  // nanoseconds, ah yeah
  },

  search: indexDefaults {
    kibanaEndpoint: 'https://00a4ef3362214c44a044feaa539b4686.us-central1.gcp.cloud.es.io:9243/app/kibana',
    timestamp: '@timestamp',
    indexPattern: '3fdde960-1f73-11eb-9ead-c594f004ece2',
    defaultFilters: [matchFilter('service.name', 'prod-gitlab-com indexing-20200330')],
    defaultColumns: ['elasticsearch.component', 'event.dataset', 'message'],
    requestsNotSupported: true,
  },

  shell: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWORyp9K1NBBQZg_dXA9',
    defaultColumns: ['json.command', 'json.msg', 'json.level', 'json.gl_project_path', 'json.error'],
    defaultSeriesSplitField: 'json.gl_project_path.keyword',
    failureFilter: [matchFilter('json.level', 'error')],
  },

  sidekiq: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'AWNABDRwNDuQHTm2tH6l',
    defaultColumns: ['json.class', 'json.queue', 'json.meta.project', 'json.job_status', 'json.scheduling_latency_s', 'json.duration_s'],
    defaultSeriesSplitField: 'json.meta.project.keyword',
    failureFilter: [matchFilter('json.job_status', 'fail')],
    defaultLatencyField: 'json.duration_s',
    latencyFieldUnitMultiplier: 1,
  },

  workhorse: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'a4f5b470-edde-11ea-81e5-155ba78758d4',
    defaultColumns: ['json.method', 'json.remote_ip', 'json.status', 'json.uri', 'json.duration_ms'],
    defaultSeriesSplitField: 'json.remote_ip.keyword',
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  workhorse_imageresizer: indexDefaults {
    timestamp: 'json.time',
    indexPattern: 'a4f5b470-edde-11ea-81e5-155ba78758d4',
    defaultFilters: [matchFilter('json.subsystem', 'imageresizer')],
    defaultColumns: ['json.method', 'json.uri', 'json.imageresizer.content_type', 'json.imageresizer.original_filesize', 'json.imageresizer.target_width', 'json.imageresizer.status'],
    defaultSeriesSplitField: 'json.uri',
    failureFilter: [mustNot(matchFilter('json.imageresizer.status', 'success'))],
  },
};

// This is similar to std.setUnion, except that the array order is maintained
// items from newItems will be added to array if they don't already exist
local appendUnion(array, newItems) =
  std.foldl(
    function(memo, item)
      if std.member(memo, item) then
        memo
      else
        memo + [item],
    newItems,
    array
  );

local buildElasticDiscoverSearchQueryURL(index, filters=[], luceneQueries=[], timeRange=grafanaTimeRange, sort=[], extraColumns=[]) =
  local ic = indexCatalog[index];

  local columnsWithExtras = appendUnion(indexCatalog[index].defaultColumns, extraColumns);

  local applicationState = {
    columns: columnsWithExtras,
    filters: ic.defaultFilters + filters,
    index: ic.indexPattern,
    [if std.length(luceneQueries) > 0 then 'query']: {
      language: 'kuery',
      query: std.join(' AND ', luceneQueries),
    },
    [if std.length(sort) > 0 then 'sort']: sort,
  };
  ic.kibanaEndpoint + '#/discover?_a=' + rison.encode(applicationState) + globalState(timeRange);

local buildElasticLineCountVizURL(index, filters, luceneQueries=[], splitSeries=false, timeRange=grafanaTimeRange) =
  local ic = indexCatalog[index];

  local aggs =
    [
      {
        enabled: true,
        id: '1',
        params: {},
        schema: 'metric',
        type: 'count',
      },
      {
        enabled: true,
        id: '2',
        params: {
          drop_partials: true,
          extended_bounds: {},
          field: ic.timestamp,
          interval: 'auto',
          min_doc_count: 1,
          scaleMetricValues: false,
          timeRange: {
            from: grafanaTimeFrom,
            to: grafanaTimeTo,
          },
          useNormalizedEsInterval: true,
        },
        schema: 'segment',
        type: 'date_histogram',
      },
    ]
    +
    (
      if splitSeries then
        [{
          enabled: true,
          id: '3',
          params: {
            field: ic.defaultSeriesSplitField,
            missingBucket: false,
            missingBucketLabel: 'Missing',
            order: 'desc',
            orderBy: '1',
            otherBucket: true,
            otherBucketLabel: 'Other',
            size: 5,
          },
          schema: 'group',
          type: 'terms',
        }]
      else
        []
    );

  local applicationState = {
    filters: ic.defaultFilters + filters,
    query: {
      language: 'kuery',
      query: std.join(' AND ', luceneQueries),
    },
    vis: {
      aggs: aggs,
    },
  };

  indexCatalog[index].kibanaEndpoint + '#/visualize/create?type=line&indexPattern=' + indexCatalog[index].indexPattern + '&_a=' + rison.encode(applicationState) + globalState(timeRange);

local splitDefinition(split, orderById='1') =
  local defaults = {
    enabled: true,
    schema: 'bucket',
  };

  if std.isString(split) then
    // When the split is a string, turn it into a 'term' split
    defaults {
      type: 'terms',
      params: {
        field: split,
        missingBucket: false,
        missingBucketLabel: 'Missing',
        otherBucket: true,
        otherBucketLabel: 'Other',
        orderBy: orderById,
        order: 'desc',
        size: 5,
      },
    }
  else if std.isObject(split) then defaults + split;

local buildElasticTableCountVizURL(index, filters, luceneQueries=[], splitSeries=false, timeRange=grafanaTimeRange, extraAggs=[], orderById='1') =
  local ic = indexCatalog[index];
  local aggs =
    [
      {
        enabled: true,
        id: '1',
        params: {},
        schema: 'metric',
        type: 'count',
      },
    ]
    +
    (
      if std.isBoolean(splitSeries) && splitSeries then
        [{
          enabled: true,
          id: '',
          params: {
            field: ic.defaultSeriesSplitField,
            missingBucket: false,
            missingBucketLabel: 'Missing',
            order: 'desc',
            orderBy: orderById,
            otherBucket: true,
            otherBucketLabel: 'Other',
            size: 5,
          },
          schema: 'group',
          type: 'terms',
        }]
      else if std.isArray(splitSeries) then
        [splitDefinition(split, orderById) for split in splitSeries]
      else
        []
    )
    +
    extraAggs;

  local applicationState = {
    filters: ic.defaultFilters + filters,
    query: {
      language: 'kuery',
      query: std.join(' AND ', luceneQueries),
    },
    vis: {
      aggs: aggs,
    },
  };

  indexCatalog[index].kibanaEndpoint + '#/visualize/create?type=table&indexPattern=' + indexCatalog[index].indexPattern + '&_a=' + rison.encode(applicationState) + globalState(timeRange);


local buildElasticLineTotalDurationVizURL(index, filters, luceneQueries=[], latencyField, splitSeries=false) =
  local ic = indexCatalog[index];

  local aggs =
    [
      {
        enabled: true,
        id: '1',
        params: {
          field: latencyField,
        },
        schema: 'metric',
        type: 'sum',
      },
      {
        enabled: true,
        id: '2',
        params: {
          drop_partials: true,
          extended_bounds: {},
          field: ic.timestamp,
          interval: 'auto',
          min_doc_count: 1,
          scaleMetricValues: false,
          timeRange: {
            from: grafanaTimeFrom,
            to: grafanaTimeTo,
          },
          useNormalizedEsInterval: true,
        },
        schema: 'segment',
        type: 'date_histogram',
      },
    ]
    +
    (
      if splitSeries then
        [{
          enabled: true,
          id: '3',
          params: {
            field: ic.defaultSeriesSplitField,
            missingBucket: false,
            missingBucketLabel: 'Missing',
            order: 'desc',
            orderBy: '1',
            otherBucket: true,
            otherBucketLabel: 'Other',
            size: 5,
          },
          schema: 'group',
          type: 'terms',
        }]
      else
        []
    );

  local applicationState = {
    filters: ic.defaultFilters + filters,
    query: {
      language: 'kuery',
      query: std.join(' AND ', luceneQueries),
    },
    vis: {
      aggs: aggs,
      params: {
        valueAxes: [
          {
            id: 'ValueAxis-1',
            name: 'LeftAxis-1',
            position: 'left',
            scale: {
              mode: 'normal',
              type: 'linear',
            },
            show: true,
            style: {},
            title: {
              text: 'Sum Request Duration: ' + latencyField,
            },
            type: 'value',
          },
        ],
      },
    },
  };

  indexCatalog[index].kibanaEndpoint + '#/visualize/create?type=line&indexPattern=' + indexCatalog[index].indexPattern + '&_a=' + rison.encode(applicationState) + globalState(grafanaTimeRange);

local buildElasticLinePercentileVizURL(index, filters, luceneQueries=[], latencyField, splitSeries=false) =
  local ic = indexCatalog[index];

  local aggs =
    [
      {
        enabled: true,
        id: '1',
        params: {
          field: latencyField,
          percents: [
            95,
          ],
        },
        schema: 'metric',
        type: 'percentiles',
      },
      {
        enabled: true,
        id: '2',
        params: {
          drop_partials: true,
          extended_bounds: {},
          field: ic.timestamp,
          interval: 'auto',
          min_doc_count: 1,
          scaleMetricValues: false,
          timeRange: {
            from: grafanaTimeFrom,
            to: grafanaTimeTo,
          },
          useNormalizedEsInterval: true,
        },
        schema: 'segment',
        type: 'date_histogram',
      },
    ] +
    (
      if splitSeries then
        [
          {
            enabled: true,
            id: '3',
            params: {
              field: ic.defaultSeriesSplitField,
              missingBucket: false,
              missingBucketLabel: 'Missing',
              order: 'desc',
              orderAgg: {
                enabled: true,
                id: '3-orderAgg',
                params: {
                  field: latencyField,
                },
                schema: 'orderAgg',
                type: 'sum',
              },
              orderBy: 'custom',
              otherBucket: true,
              otherBucketLabel: 'Other',
              size: 5,
            },
            schema: 'group',
            type: 'terms',
          },
        ]
      else
        []
    );

  local applicationState = {
    filters: ic.defaultFilters + filters,
    query: {
      language: 'kuery',
      query: std.join(' AND ', luceneQueries),
    },
    vis: {
      aggs: aggs,
      params: {
        valueAxes: [
          {
            id: 'ValueAxis-1',
            name: 'LeftAxis-1',
            position: 'left',
            scale: {
              mode: 'normal',
              type: 'linear',
            },
            show: true,
            style: {},
            title: {
              text: 'p95 Request Duration: ' + latencyField,
            },
            type: 'value',
          },
        ],
      },
    },
  };

  indexCatalog[index].kibanaEndpoint + '#/visualize/create?type=line&indexPattern=' + indexCatalog[index].indexPattern + '&_a=' + rison.encode(applicationState) + globalState(grafanaTimeRange);


{
  matcher:: matcher,
  matchers:: matchers,
  matchFilter:: matchFilter,
  existsFilter:: existsFilter,
  rangeFilter:: rangeFilter,

  timeRange:: elasticTimeRange,

  // Given an index, and a set of filters, returns a URL to a Kibana discover module/search
  buildElasticDiscoverSearchQueryURL:: buildElasticDiscoverSearchQueryURL,

  // Search for failed requests
  buildElasticDiscoverFailureSearchQueryURL(index, filters=[], luceneQueries=[], timeRange=grafanaTimeRange, sort=[], extraColumns=[])::
    buildElasticDiscoverSearchQueryURL(
      index=index,
      filters=filters + indexCatalog[index].failureFilter,
      luceneQueries=luceneQueries,
      timeRange=timeRange,
      sort=sort,
      extraColumns=extraColumns
    ),

  // Search for requests taking longer than the specified number of seconds
  buildElasticDiscoverSlowRequestSearchQueryURL(index, filters=[], luceneQueries=[], slowRequestSeconds, timeRange=grafanaTimeRange, extraColumns=[])::
    local ic = indexCatalog[index];
    local slowRequestFilter = if std.objectHas(ic, 'slowRequestFilter') then ic.slowRequestFilter else [];

    buildElasticDiscoverSearchQueryURL(
      index=index,
      filters=filters + slowRequestFilter + [rangeFilter(ic.defaultLatencyField, gteValue=slowRequestSeconds * ic.latencyFieldUnitMultiplier, lteValue=null)],
      timeRange=timeRange,
      sort=[[ic.defaultLatencyField, 'desc']],
      extraColumns=extraColumns
    ),

  // Given an index, and a set of filters, returns a URL to a Kibana count visualization
  buildElasticLineCountVizURL(index, filters, luceneQueries=[], splitSeries=false, timeRange=grafanaTimeRange,)::
    buildElasticLineCountVizURL(index, filters, luceneQueries, splitSeries=splitSeries, timeRange=timeRange),

  buildElasticLineFailureCountVizURL(index, filters, luceneQueries=[], splitSeries=false, timeRange=grafanaTimeRange)::
    buildElasticLineCountVizURL(
      index,
      filters + indexCatalog[index].failureFilter,
      luceneQueries,
      splitSeries=splitSeries,
      timeRange=timeRange,
    ),

  buildElasticTableCountVizURL:: buildElasticTableCountVizURL,
  buildElasticTableFailureCountVizURL(index, filters, luceneQueries=[], splitSeries=false, timeRange=grafanaTimeRange)::
    buildElasticTableCountVizURL(index, filters + indexCatalog[index].failureFilter, luceneQueries, splitSeries, timeRange),

  /**
   * Builds a total (sum) duration visualization. These queries are particularly useful for picking up
   * high volume short queries and can be useful in some types of incident investigations
   */
  buildElasticLineTotalDurationVizURL(index, filters, luceneQueries=[], field=null, splitSeries=false)::
    local fieldWithDefault = if field == null then
      indexCatalog[index].defaultLatencyField
    else
      field;
    buildElasticLineTotalDurationVizURL(index, filters, luceneQueries, fieldWithDefault, splitSeries=splitSeries),

  // Given an index, and a set of filters, returns a URL to a Kibana percentile visualization
  buildElasticLinePercentileVizURL(index, filters, luceneQueries=[], field=null, splitSeries=false)::
    local fieldWithDefault = if field == null then
      indexCatalog[index].defaultLatencyField
    else
      field;
    buildElasticLinePercentileVizURL(index, filters, luceneQueries, fieldWithDefault, splitSeries=splitSeries),

  // Returns true iff the named index supports request graphs (some do not have a concept of 'requests')
  indexSupportsRequestGraphs(index)::
    !std.objectHas(indexCatalog[index], 'requestsNotSupported'),

  // Returns true iff the named index supports failure queries
  indexSupportsFailureQueries(index)::
    std.objectHas(indexCatalog[index], 'failureFilter'),

  // Returns true iff the named index supports latency queries
  indexSupportsLatencyQueries(index)::
    std.objectHas(indexCatalog[index], 'defaultLatencyField'),

  /**
   * Best-effort converter for a prometheus selector hash,
   * to convert it into a ES matcher.
   * Returns an array of zero or more matchers.
   *
   * TODO: for now, only supports equal matches, re (single value), eq, ne, improve this
   */
  getMatchersForPrometheusSelectorHash(index, selectorHash)::
    local prometheusLabelMappings = defaultPrometheusLabelMappings + indexCatalog[index].prometheusLabelMappings;

    std.flatMap(
      function(label)
        if std.objectHas(prometheusLabelMappings, label) then
          local selectorValue = selectorHash[label];

          // A mapping from this prometheus label to a ES field exists
          if std.isString(selectorValue) then
            [matchFilter(prometheusLabelMappings[label], selectorValue)]
          else if std.objectHas(selectorValue, 're') then
            // Most of the time, re contains a single value,
            // so treating it as such is better than ignoring
            [matchFilter(prometheusLabelMappings[label], selectorValue.re)]
          else if std.objectHas(selectorValue, 'eq') then
            // Most of the time, re contains a single value,
            // so treating it as such is better than ignoring
            [matchFilter(prometheusLabelMappings[label], selectorValue.eq)]
          else if std.objectHas(selectorValue, 'ne') then
            // Most of the time, re contains a single value,
            // so treating it as such is better than ignoring
            [mustNot(matchFilter(prometheusLabelMappings[label], selectorValue.ne))]
          else
            []
        else
          [],
      std.objectFields(selectorHash)
    ),

  getCustomTimeRange(from, to):: "(time:(from:'" + from + "',to:'" + to + "'))",

  dashboards:: {
    // A dashboard for reviewing rails log metrics
    // The caller_id is the route or the controller#action
    railsEndpointDashboard(caller_id, from='now-24', to='now')::
      local globalState = {
        filters: [
          {
            query: {
              match_phrase: {
                'json.meta.caller_id.keyword': '{{#url}}{{key}}{{/url}}',
              },
            },
          },
        ],
        time: { from: from, to: to },
      };
      local g = rison.encode(globalState);
      'https://log.gprd.gitlab.net/app/dashboards#/view/db37b560-9793-11eb-a990-d72c312ff8e9?_g=' + g,
  },
}
