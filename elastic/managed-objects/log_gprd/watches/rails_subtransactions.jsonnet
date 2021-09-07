{
  trigger: {
    schedule: {
      interval: '15m',
    },
  },
  input: {
    search: {
      request: {
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
                      gte: 'now-30m',
                      lte: 'now',
                    },
                  },
                },
                {
                  match_phrase: {
                    'json.class': 'Gitlab::Database::Transaction::Context',
                  },
                },
                {
                  range: {
                    'json.savepoints_count': {
                      gt: 0,
                    },
                  },
                },
              ],
            },
          },
          size: 0,
        },
      },
    },
  },
  condition: {
    compare: {
      'ctx.payload.hits.total': {
        gt: 0,
      },
    },
  },
  actions: {
    'notify-slack': {
      throttle_period_in_millis: 420000,
      slack: {
        message: {
          from: 'ElasticCloud Watcher: Subtransactions detected',
          to: [
            '#subtransaction_troubleshooting',
          ],
          text: 'There are {{ctx.payload.hits.total}} subtransactions detected in the logs collected in the last 30 minutes. See them in Rails: https://log.gprd.gitlab.net/goto/ef66c78edf65016ffeb7caf0fb3912a7 and in Sidekiq: https://log.gprd.gitlab.net/goto/cfc096f18757764fcf6c2e44b3af1c66',
        },
      },
    },
  },
}
