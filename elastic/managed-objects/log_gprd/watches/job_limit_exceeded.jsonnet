local schedule_mins = 5;  // Run this watch at this frequency, in minutes
local query_period = schedule_mins + 2;
local alert_threshold = 0;

// Using this a variant of query:
// https://log.gprd.gitlab.net/goto/c6e1fe51e851414d878f59c8b043c1a5
local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
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
            match_phrase: {
              'json.exception.class': 'Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError',
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
          from: 'ElasticCloud Watcher: Sidekiq job rejected',
          to: [
            '#scalability-490-sidekiq-job-limits',
          ],
          text: 'Sidekiq jobs with a compressed payload > 5MB are being rejected. Please investigate this further. See https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/490 and https://log.gprd.gitlab.net/goto/321a6c1bb2b8ebd0432508c2de7645b8',
        },
      },
    },
  },
}
