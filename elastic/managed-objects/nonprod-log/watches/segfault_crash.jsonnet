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
            match_phrase: {
              'json.message': '[BUG] Segmentation fault',
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
          from: 'ElasticCloud Watcher: Segfault crash',
          to: [
            '#staging',
          ],
          text: 'Segmentation fault: {{ctx.payload.hits.total}} errors detected!',
          attachments: [
            {
              title: ':spiral_note_pad: Segmentation faults in Rails logs:',
              text: 'https://nonprod-log.gitlab.net/goto/27cd6690-85ff-11ec-b3a6-472d0398dd6e',
            },
            {
              title: ':spiral_note_pad: Segmentation faults in Sidekiq logs:',
              text: 'https://nonprod-log.gitlab.net/goto/3572e680-85ff-11ec-b3a6-472d0398dd6e',
            },
            {
              title: ':runbooks: Runbook:',
              text: 'https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/uncategorized/staging-environment.md#elasticcloud-watcher-segmentation-faults',
            },
          ],
        },
      },
    },
  },
}
