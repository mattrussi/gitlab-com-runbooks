local query_period = '24h';
local run_time = '01:00';
local alert_threshold = 1;

local es_query = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
  ],
  rest_total_hits_as_int: true,

  body: {
    size: 100,
    query: {
      bool: {
        must: [],
        filter: [
          {
            match_all: {},
          },
          {
            match_phrase: {
              'json.meta.feature_category.keyword': 'global_search',
            },
          },
          {
            exists: {
              field: 'json.meta.search.scope',
            },
          },
          {
            range: {
              '@timestamp': { gte: std.format('now-%dm', query_period), lte: 'now' },
            },
          },
        ],
        should: [],
        must_not: [
          {
            bool: {
              minimum_should_match: 1,
              should: [
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'milestones',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'issues',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'users',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'merge_requests',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'notes',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'commits',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'wiki_blobs',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'projects',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'blobs',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': '',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'epics',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'snippet_titles',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': 'code',
                  },
                },
                {
                  match_phrase: {
                    'json.meta.search.scope.keyword': '1',
                  },
                },
              ],
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
      daily: {
        at: run_time,
      },
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
    'index-abusive-searches': {
      transform: {
        script: {
          source: |||
            def documents = ctx.payload.hits.hits.stream()
                .map(hit -> [
                  "json": hit._source.json
                ])
                .collect(Collectors.toList());
              return [ "_doc" : documents];
          |||,
          lang: 'painless',
        },
      },
      index: {
        index: 'abuse-global-search-rails-000001',
      },
    },
    'notify-slack': {
      slack: {
        account: 'gitlab_team',
        message: {
          from: 'ElasticCloud Watcher:  Abuse Detection',
          to: [
            '#g_global_search_alerts',
          ],
          text: |||
            There have been {{ ctx.payload.hits.total }} searches with abusive scopes in the past 24 hours.
            :kibana: <https://log.gprd.gitlab.net/app/discover#/view/ea2d4430-4d6a-11ec-a012-eb2e5674cacf?_g=(filters%3A!()%2CrefreshInterval%3A(pause%3A!t%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1d%2Cto%3Anow))|Kibana query>
          |||,
        },
      },
    },
  },
}
