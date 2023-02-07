local schedule_mins = 720;  // Run this watch at this frequency, in minutes
local query_period = schedule_mins + 2;
local alert_threshold = 0;

local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
    'pubsub-sidekiq-inf-gprd-*',
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
            match_phrase: {
              'json.subcomponent': 'deprecation_json',
            },
          },
          {
            // Exclude "Logfile created" messages
            bool: {
              must_not: [
                {
                  match_phrase: {
                    'json.message': 'Logfile created',
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
          from: 'ElasticCloud Watcher: Deprecation warnings',
          to: [
            '#deprecation-warnings-test',
          ],
          text: 'Deprecations: {{ctx.payload.hits.total}} warnings detected! These can turn into hard failures if a library is upgraded.',
          attachments: [
            {
              title: ':rails: Rails deprecation warnings:',
              text: 'https://log.gprd.gitlab.net/goto/bc4a52c0-a62d-11ed-9f43-e3784d7fe3ca',
            },
            {
              title: ':sidekiq: Sidekiq deprecation warnings:',
              text: 'https://log.gprd.gitlab.net/goto/dcec0d70-a62d-11ed-9f43-e3784d7fe3ca',
            },
          ],
        },
      },
    },
  },
}
