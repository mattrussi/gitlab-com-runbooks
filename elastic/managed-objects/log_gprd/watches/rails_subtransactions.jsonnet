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
                      gte: 'now-20m',
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
      throttle_period: '20m',
      slack: {
        message: {
          from: 'Elastic Logs: Subtransactions detected',
          to: [
            '#subtransaction_troubleshooting',
          ],
          text: ':postgres: {{ctx.payload.hits.total}} new transaction/s using subtransactions detected in the logs collected in the last 30 minutes!',
          attachments: [
            {
              title: ':spiral_note_book: Subtransactions in Rails logs:',
              text: 'https://log.gprd.gitlab.net/goto/ef66c78edf65016ffeb7caf0fb3912a7',
            },
            {
              title: ':spiral_note_book: Subtransactions in Sidekiq logs:',
              text: 'https://log.gprd.gitlab.net/goto/ef66c78edf65016ffeb7caf0fb3912a7',
            },
            {
              title: ':runbooks: Runbook:',
              text: 'https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/postgresql/subtransactions.md',
            },
          ],
        },
      },
    },
  },
}
