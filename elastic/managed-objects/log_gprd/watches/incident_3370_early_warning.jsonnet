local TRIGGER_SCHEDULE_MINS = 2;  // Run this watcher at this frequency, in minutes

local params = {
};

local ES_QUERY = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
  ],
  types: [],
  body: {
    aggs: {
      hostnames: {
        terms: {
          field: 'json.hostname.keyword',
          order: {
            _count: 'desc',
          },
          size: 20,
        },
      },
    },
    size: 0,
    query: {
      bool: {
        must: [
          {
            match_all: {},
          },
        ],
        filter: [
          {
            match_phrase: {
              'json.exception.class': 'ActionView::Template::Error',
            },
          },
          {
            bool: {
              should: [
                {
                  match_phrase: {
                    'json.exception.message': 'uninitialized constant',
                  },
                },
                {
                  match_phrase: {
                    'json.exception.message': 'undefined const_missing',
                  },
                },
              ],
              minimum_should_match: 1,
            },
          },
          {
            match_phrase: {
              'json.type.keyword': 'web',
            },
          },
          {
            range: {
              'json.time': {
                gt: 'now-5m',
                lte: 'now',
              },
            },
          },
        ],
      },
    },
  },
};

local conditionScript = |||
  ctx.payload.aggregations.hostnames.buckets.length() > 0
|||;

local painlessScript(script) = {
  script: {
    inline: script,
    lang: 'painless',
    params: params,
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
  condition: painlessScript(conditionScript),
  actions: {
    'notify-slack': {
      throttle_period: '2m',
      slack: {
        account: 'gitlab_team',
        message: {
          from: 'ElasticCloud Watcher: incident #3370 early warning system',
          to: [
            '#production',
          ],
          text: 'Unusual rails logs detected which may incident a corrupted web node. Please investigate immediately. <https://log.gprd.gitlab.net/goto/8b155c41c1b2a385a00fd5151ee5b85b> Incident issue is <https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3370>',
        },
      },
    },
  },
}
