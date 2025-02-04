local schedule_mins = 1;  // Run this watch at this frequency, in minutes
local query_period = schedule_mins + 1;  // Allow for some overlap in case there is a delay with scheduling the query; redundancy is OK
local alert_threshold = 0;

local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
  ],
  rest_total_hits_as_int: true,
  body: {
    query: {
      bool: {
        must: [],
        filter: [
          {
            range: {
              '@timestamp': { gte: std.format('now-%dm', query_period), lte: 'now' },
            },
          },
          {
            match_phrase: {
              "json.jsonPayload.logger": "cloud_connector"
            }
          },
          {
            bool: {
              should: [
                {
                  bool: {
                    filter: [
                      {
                        match_phrase: {
                          "json.jsonPayload.message.keyword": "Old JWKS re-cached: some key providers failed"
                        }
                      }
                    ],
                  }
                },
                {
                  bool: {
                    filter: [
                      {
                        match_phrase: {
                          "json.jsonPayload.message.keyword": "Incomplete JWKS cached: some key providers failed, no old cache to fall back to"
                        }
                      }
                    ],
                  }
                }
              ],
              minimum_should_match: 1
            }
          }
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
      request: es_query
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
          from: 'ElasticCloud Watcher: AI GW OIDC fetch failure!'
          to: [
            '#cloud-connector-events',
          ],
          text: |||
            AI Gateway: JWKS sync failed!
            :kibana: <https://log.gprd.gitlab.net/app/r/s/ozSIe|Errors over last 24 hours>
          |||,
        },
      },
    },
  },
},
