local query_period = '24h';
local run_time = '01:00';
local alert_threshold = 1;

local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
  ],
  rest_total_hits_as_int: true,

  body: {
    size: 100,
    query: {
      bool: {
        must: [],
        filter: [
          {
            range: {
              '@timestamp': { gte: std.format('now-%dm', query_period), lte: 'now' },
            },
          },
          {
            match_phrase: {
              'json.message': 'redacted_search_results',
            },
          },
          {
            match_phrase: {
              'json.meta.feature_category': 'global_search',
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
      daily: {
        at: run_time,
      },
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
    'notify-slack': {
      slack: {
        account: 'gitlab_team',
        message: {
          from: 'ElasticCloud Watcher:  Redacted Search Results Detected',
          to: [
            '#g_global_search_alerts',
          ],
          text: |||
            There have been {{ ctx.payload.hits.total }} searches with redacted search results in the past 24 hours.
            :kibana: <https://log.gprd.gitlab.net/app/r/s/Bgcx6|Kibana query>'
          |||,
        },
      },
    },
  },
}
