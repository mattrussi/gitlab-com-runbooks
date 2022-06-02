// Watcher to notify when mailroom workers (EmailReceiverWorker and
// ServiceDeskEmailReceiverWorker) gets an unexpected exception
// For https://gitlab.com/gitlab-com/gl-infra/production/-/issues/7124
local schedule_mins = 5;  // Run this watch at this frequency, in minutes
local query_period = schedule_mins + 2;
local alert_threshold = 0;

// Using this a variant of query:
// https://log.gprd.gitlab.net/goto/4dd1ac50-e19b-11ec-aade-19e9974a7229
local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-sidekiq-inf-gprd-*',
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
                    'json.class': 'EmailReceiverWorker',
                  },
                },
                {
                  match_phrase: {
                    'json.class': 'ServiceDeskEmailReceiverWorker',
                  },
                },
              ],
              minimum_should_match: 1,
            },
          },
          {
            exists: {
              field: 'json.exception.class',
            },
          },
          {
            // Exclude: https://gitlab.com/gitlab-org/gitlab/-/issues/340186
            bool: {
              must_not: [
                {
                  match_phrase: {
                    // Exceptions logged by the application proactively
                    'json.exception.class': 'Gitlab::Email',
                  },
                },
                {
                  match_phrase: {
                    // Timeout when processing the email. Nothing we can do
                    'json.exception.class': 'ActiveRecord::QueryCanceled',
                  },
                },
              ],
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
          from: 'ElasticCloud Watcher: MailRoom jobs have got exceptions',
          to: [
            '#alerts_mailroom',
          ],
          text: 'MailRoom jobs have got exceptions while processing. Logs:  https://log.gprd.gitlab.net/goto/4dd1ac50-e19b-11ec-aade-19e9974a7229. Please check this issue for more information: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/7124',
        },
      },
    },
  },
}
