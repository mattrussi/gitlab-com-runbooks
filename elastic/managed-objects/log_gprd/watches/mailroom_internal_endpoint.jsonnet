// Watcher to notify when internal mailroom endpoint /api/v4/internal/mail_room
// gets any unexpected 500 errors
// For https://gitlab.com/gitlab-com/gl-infra/production/-/issues/7124
local schedule_mins = 5;  // Run this watch at this frequency, in minutes
local query_period = schedule_mins + 2;
local alert_threshold = 0;

// Using this a variant of query:
// https://log.gprd.gitlab.net/goto/8948e8c0-e19b-11ec-aade-19e9974a7229
local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
  ],
  types: [],
  body: {
    size: 0,
    query: {
      bool: {
        must: [
          {
            range: {
              '@timestamp': { gte: std.format('now-%dm', query_period), lte: 'now' },
            },
          },
          {
            bool: {
              should: [
                {
                  match_phrase: {
                    'json.status': '500',
                  },
                },
                {
                  match_phrase: {
                    'json.path': '/api/v4/internal/mail_room',
                  },
                },
              ],
              minimum_should_match: 2,
            },
          },
        ],
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
        gt: alert_threshold,
      },
    },
  },
  actions: {
    'notify-slack': {
      throttle_period: query_period + 'm',
      slack: {
        message: {
          from: 'ElasticCloud Watcher: MailRoom internal endpoint returns 500 status',
          to: [
            '#alerts_mailroom',
          ],
          text: 'MailRoom internal endpoint returned 500 status. Logs: https://log.gprd.gitlab.net/goto/8948e8c0-e19b-11ec-aade-19e9974a7229. Please check this issue for more information: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/7124',
        },
      },
    },
  },
}
