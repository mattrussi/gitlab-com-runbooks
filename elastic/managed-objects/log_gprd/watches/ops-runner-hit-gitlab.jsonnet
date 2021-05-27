// https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/227
local TRIGGER_SCHEDULE_MINS = 5;  // Run this watch at this frequency, in minutes
local QUERY_PERIOD_MINS = 5;
local ALERT_THRESHOLD = 0;

local ES_QUERY = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
  ],
  types: [],
  body: {
    size: 0,
    query: {
      bool: {
        should: [
          {
            match_phrase: {
              'json.remote_ip.keyword': '35.231.50.113',
            },
          },
          {
            match_phrase: {
              'json.remote_ip.keyword': '35.185.18.176',
            },
          },
        ],
        minimum_should_match: 1,
        must: [
          { range: { '@timestamp': { gte: std.format('now-%dm', QUERY_PERIOD_MINS), lte: 'now' } } },
        ],
      },
    },
  },
};
{
  trigger: {
    schedule: {
      interval: std.format('%dm', TRIGGER_SCHEDULE_MINS),
    },
  },
  input: {
    search: {
      request: ES_QUERY,
    },
  },
  condition: {
    compare: {
      'ctx.payload.hits.total': {
        gt: ALERT_THRESHOLD,
      },
    },
  },
  actions: {
    'notify-slack': {
      throttle_period: QUERY_PERIOD_MINS + 'm',
      slack: {
        message: {
          from: 'ElasticCloud Watcher: ops runners hitting Gitlab.com',
          to: [
            '#ops-runner-gitlab-alert',
          ],
          text: 'We have detected ops runners hitting Gitlab.com. Please investigate this further. See: https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/227 for more information.',
        },
      },
    },
  },
}
