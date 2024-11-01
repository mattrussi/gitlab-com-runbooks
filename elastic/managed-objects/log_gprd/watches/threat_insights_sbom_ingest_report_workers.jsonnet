local schedule_mins = 90;
local query_period = schedule_mins;
local alert_threshold = 20;

local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-sidekiq-inf-gprd',
  ],
  rest_total_hits_as_int: true,
  body: {
    size: 0,
    query: {
      bool: {
        must: [
          {
            match_phrase: {
              'json.job_status.keyword': 'fail',
            },
          },
          {
            match_phrase: {
              'json.class.keyword': 'Sbom::IngestReportsWorker',
            },
          },

          {
            range: {
              '@timestamp': { gte: std.format('now-%dm', query_period), lte: 'now', format: 'strict_date_optional_time||epoch_millis' },
            },
          },
        ],
        must_not: [
          {
            match_phrase: {
              'json.exception.message.keyword': 'Failed to obtain a lock',
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
      slack: {
        message: {
          to: [
            'g_govern_threat_insights',

          ],
          text: |||
            Watch [{{ctx.metadata.name}}] has exceeded the threshold.
            <Failed jobs log|https://log.gprd.gitlab.net/app/discover#/view/6fc5c9df-7720-440c-9921-04cf9ed7cdbc?_g=()>
          |||,
        },
      },
    },
    transform: {
      script: {
        source: 'HashMap result = new HashMap(); result.result = ctx.payload.hits.total; return result;',
        lang: 'painless',
        params: {
          threshold: 20,
        },
      },
    },
  },
}
