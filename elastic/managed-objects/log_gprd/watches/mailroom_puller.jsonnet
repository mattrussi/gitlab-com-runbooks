// Watcher to notify when mailroom process (puller) gets an erro
// For https://gitlab.com/gitlab-com/gl-infra/production/-/issues/7124
local schedule_mins = 720;  // Run this watch at this frequency, 12 hours in minutes
local query_period = schedule_mins + 2;
local alert_threshold = 5;

// Using this a variant of query:
// https://log.gprd.gitlab.net/goto/7d651600-e19b-11ec-8741-ad075583b944
local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-mailroom-inf-gprd-*',
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
                    'json.severity': 'error',
                  },
                },
                {
                  match_phrase: {
                    'json.severity': 'fatal',
                  },
                },
              ],
              minimum_should_match: 1,
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
          from: 'ElasticCloud Watcher: MailRoom process gets some errors',
          to: [
            '#alerts_mailroom',
          ],
          text: 'MailRoom process logged errors. This could be caused by a process restart. Logs: https://log.gprd.gitlab.net/goto/7d651600-e19b-11ec-8741-ad075583b944. Please check this issue for more information: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/7124',
        },
      },
    },
  },
}
