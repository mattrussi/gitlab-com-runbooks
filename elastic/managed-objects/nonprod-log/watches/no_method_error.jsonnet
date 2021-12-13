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
                        'json.exception.message': 'undefined method',
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
                        'json.error_message': 'undefined method',
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
          text: 'NoMethodError: {{ctx.payload.hits.total}} errors detected!',
          attachments: [
            {
              title: ':spiral_note_pad: NoMethodError in Rails logs:',
              text: 'https://nonprod-log.gitlab.net/goto/519d702153ace63726c53c006469bbc5',
            },
            {
              title: ':spiral_note_pad: NoMethodError in Sidekiq logs:',
              text: 'https://nonprod-log.gitlab.net/goto/f9121db72183cf50d161b806f96ddb0b',
            },
            {
              title: ':runbooks: Runbook:',
              text: 'https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/uncategorized/staging-environment.md#elasticcloud-watcher-nomethoderror',
            },
          ],
        },
      },
    },
  },
}
