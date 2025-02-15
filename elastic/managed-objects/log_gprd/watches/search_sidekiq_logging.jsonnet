local schedule_mins = 30;
local query_period = schedule_mins;
local alert_threshold = 1;

local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
  ],
  rest_total_hits_as_int: true,

  body: {
    query: {
      bool: {
        must: [],
        filter: [
          {
            bool: {
              must: [
                {
                  match: {
                    'json.class': 'ElasticDeleteProjectWorker',
                  },
                },
              ],
            },
          },
          {
            range: {
              '@timestamp': { gte: std.format('now-%dm', query_period), lte: 'now' },
            },
          },
        ],
        should: [],
        must_not: [],
      },
    },
  },
};

{
  trigger: {
    schedule: {
      interval: std.format('%dm', schedule_mins),
    },
  },
  input: {
    search: {
      request: es_query,
    },
  },
  condition: {
    compare: {
      'ctx.payload.hits.total': {
        gte: alert_threshold,
      },
    },
  },
  actions: {
    'index-items': {
      transform: {
        script: {
          source: |||
            def documents = ctx.payload.hits.hits.stream()
              .map(hit -> [
                "@timestamp": hit._source["@timestamp"],
                "json": hit._source.json
              ])
              .collect(Collectors.toList());

            return [ "_doc" : documents]
          |||,
          lang: 'painless',
        },
      },
      index: {
        index: 'search-team-sidekiq-000001',

      },
    },
  },
}
