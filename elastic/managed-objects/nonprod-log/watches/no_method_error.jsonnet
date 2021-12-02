local schedule_mins = 15;  // Run this watch at this frequency, in minutes
local query_period = schedule_mins + 2;
local alert_threshold = 0;

local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gstg*',
    'pubsub-sidekiq-inf-gstg*',
  ],
  rest_total_hits_as_int: true,
  body: {
    query: {
      bool: {
        must: [
          {
            range: {
              '@timestamp': {
                gte: std.format('now-%dm', query_period),
                lte: 'now',
              },
            },
          },
          {
            bool: {
              minimum_should_match: 1,
              should: [
                {
                  bool: {
                    must: {
                      match_phrase: {
                        'json.exception.class': 'NoMethodError',
                      },
                    },
                    must_not: {
                      match_phrase: {
                        'json.exception.message': '"nil:NilClass"',
                      },
                    },
                  },
                },
                {
                  bool: {
                    must: {
                      match_phrase: {
                        'json.error_class': 'NoMethodError',
                      },
                    },
                    must_not: {
                      match_phrase: {
                        'json.error_message': '"nil:NilClass"',
                      },
                    },
                  },
                },
              ],
            },
          },
        ],
      },
    },
    size: 0,
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
        gt: alert_threshold,
      },
    },
  },
  actions: {
    'notify-slack': {
      throttle_period: query_period + 'm',
      slack: {
        message: {
          from: 'ElasticCloud Watcher: NoMethodError',
          to: [
            '#staging',
          ],
          text: 'NoMethodError: {{ctx.payload.hits.total}} errors detected! Please investigate. See https://gitlab.com/gitlab-org/gitlab/-/issues/345957 and https://nonprod-log.gitlab.net/goto/86a259d07d53400c9b4526f1dcf66fec',
        },
      },
    },
  },
}
