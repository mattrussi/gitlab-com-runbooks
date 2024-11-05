local query_period = 1440;
local run_time = '01:00';
local alert_threshold = 1;

local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
  ],
  rest_total_hits_as_int: true,

  body: {
    size: 0,
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
            range: {
              'json.db_count': {
                gte: 300,
              },
            },
          },
          {
            match_phrase: {
              'json.controller': 'SearchController',
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
          from: 'ElasticCloud Watcher:  High number of database calls detected',
          to: [
            '#g_global_search_alerts',
          ],
          text: |||
            There have been {{ ctx.payload.hits.total }} searches with a high number of database calls in the past 24 hours.
            :kibana: <https://log.gprd.gitlab.net/app/r/s/TnEKf|Kibana query>
          |||,
        },
      },
    },
  },
}
