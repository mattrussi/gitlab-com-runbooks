local schedule_mins = 720;  // Run this watch at this frequency, in minutes
local query_period = schedule_mins + 2;
local alert_threshold = 0;

local es_query = function(index)
  {
    search_type: 'query_then_fetch',
    indices: [
      index,
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
  watcher:: function(index, title, link)
    {
      trigger: {
        schedule: {
          interval: std.format('%dm', schedule_mins),
        },
      },
      input: {
        search: {
          request: es_query(index),
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
              from: 'ElasticCloud Watcher: %(title)s deprecations' % {
                title: title,
                titleLower: std.asciiLower(title),
              },
              to: [
                '#backend',
              ],
              text: '{{ctx.payload.hits.total}} deprecation warnings detected. These can turn into hard failures if a library is upgraded.',
              attachments: [
                {
                  title: ':warning: Latest warnings:',
                  text: link,
                },
              ],
            },
          },
        },
      },
    },
}
