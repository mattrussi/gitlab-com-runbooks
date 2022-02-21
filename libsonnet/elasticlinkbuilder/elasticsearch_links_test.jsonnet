local elastic = import 'elasticsearch_links.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

local joinMulti(string) =
  local lines = std.split(string, '\n');
  local stripLines = std.map(function(l) std.stripChars(l, ' \t'), lines);
  std.join('', stripLines);


test.suite({
  testMatcherFilter: {
    actual: elastic.matcher('fieldName', 'test'),
    expect: {
      query: {
        match: {
          fieldName: {
            query: 'test',
            type: 'phrase',
          },
        },
      },
    },
  },
  testMatcherFilterIn: {
    actual: elastic.matcher('fieldName', ['hello', 'world']),
    expect: {
      meta: {
        key: 'query',
        type: 'custom',
        value: '{"bool": {"minimum_should_match": 1, "should": [{"match_phrase": {"fieldName": "hello"}}, {"match_phrase": {"fieldName": "world"}}]}}',
      },
      query: {
        bool: {
          should: [
            { match_phrase: { fieldName: 'hello' } },
            { match_phrase: { fieldName: 'world' } },
          ],
          minimum_should_match: 1,
        },
      },
    },
  },
  testMatchers: {
    actual: elastic.matchers({
      fieldName: ['hello', 'world'],
      rangeTest: { gte: 1, lte: 10 },
      equalMatch: 'match the exact thing',
      anyScript: ["doc['json.duration_s'].value > doc['json.target_duration_s'].value", 'script 2'],
    }),
    expect: [
      {
        query: {
          bool: {
            minimum_should_match: 1,
            should: [
              { script: { script: { source: "doc['json.duration_s'].value > doc['json.target_duration_s'].value" } } },
              { script: { script: { source: 'script 2' } } },
            ],
          },
        },
      },
      {
        query: {
          match: {
            equalMatch: {
              query: 'match the exact thing',
              type: 'phrase',
            },
          },
        },
      },
      {
        meta: {
          key: 'query',
          type: 'custom',
          value: '{"bool": {"minimum_should_match": 1, "should": [{"match_phrase": {"fieldName": "hello"}}, {"match_phrase": {"fieldName": "world"}}]}}',
        },
        query:
          {
            bool: {
              minimum_should_match: 1,
              should: [
                { match_phrase: { fieldName: 'hello' } },
                { match_phrase: { fieldName: 'world' } },
              ],
            },
          },
      },
      { query: { range: { rangeTest: { gte: 1, lte: 10 } } } },
    ],
  },
  testBuildElasticDiscoverSearchQueryURL: {
    actual: elastic.buildElasticDiscoverSearchQueryURL(
      index='sidekiq',
      filters=[
        {
          query: {
            match: {
              'json.shard': {
                query: 'throttled',
                type: 'phrase',
              },
            },
          },
        },
      ]
    ),
    expect: joinMulti(|||
      https://log.gprd.gitlab.net/app/kibana#/discover?
      _a=(columns:!(json.class,json.queue,json.meta.project,json.job_status,json.scheduling_latency_s,json.duration_s),filters:!((query:(match:(json.shard:(query:throttled,type:phrase))))),index:'AWNABDRwNDuQHTm2tH6l')&
      _g=(time:(from:'${__from:date:iso}',to:'${__to:date:iso}'))
    |||),
  },
  testBuildElasticDiscoverSearchQueryURLWithExtraColumns: {
    actual: elastic.buildElasticDiscoverSearchQueryURL(
      index='sidekiq',
      extraColumns=['json.username'],
      timeRange=null,
    ),
    expect: joinMulti(|||
      https://log.gprd.gitlab.net/app/kibana#/discover?
      _a=(columns:!(json.class,json.queue,json.meta.project,json.job_status,json.scheduling_latency_s,json.duration_s,json.username),filters:!(),index:'AWNABDRwNDuQHTm2tH6l')
    |||),
  },
  testBuildElasticLineCountVizURL: {
    actual: elastic.buildElasticLineCountVizURL(
      index='sidekiq',
      filters=[
        {
          query: {
            match: {
              'json.shard': {
                query: 'throttled',
                type: 'phrase',
              },
            },
          },
        },
      ]
    ),
    expect: joinMulti(|||
      https://log.gprd.gitlab.net/app/kibana#/visualize/create?
      type=line&
      indexPattern=AWNABDRwNDuQHTm2tH6l&
      _a=(filters:!((query:(match:(json.shard:(query:throttled,type:phrase))))),query:(language:kuery,query:''),vis:(aggs:!((enabled:!t,id:'1',params:(),schema:metric,type:count),(enabled:!t,id:'2',params:(drop_partials:!t,extended_bounds:(),field:json.time,interval:auto,min_doc_count:1,scaleMetricValues:!f,timeRange:(from:'${__from:date:iso}',to:'${__to:date:iso}'),useNormalizedEsInterval:!t),schema:segment,type:date_histogram))))&
      _g=(time:(from:'${__from:date:iso}',to:'${__to:date:iso}'))
    |||),
  },
  testBuildElasticLineTotalDurationVizURL: {
    actual: elastic.buildElasticLineTotalDurationVizURL(
      index='sidekiq',
      filters=[
        {
          query: {
            match: {
              'json.shard': {
                query: 'throttled',
                type: 'phrase',
              },
            },
          },
        },
      ],
      splitSeries=false
    ),
    expect: joinMulti(|||
      https://log.gprd.gitlab.net/app/kibana#/visualize/create?
      type=line&
      indexPattern=AWNABDRwNDuQHTm2tH6l&
      _a=(filters:!((query:(match:(json.shard:(query:throttled,type:phrase))))),query:(language:kuery,query:''),vis:(aggs:!((enabled:!t,id:'1',params:(field:json.duration_s),schema:metric,type:sum),(enabled:!t,id:'2',params:(drop_partials:!t,extended_bounds:(),field:json.time,interval:auto,min_doc_count:1,scaleMetricValues:!f,timeRange:(from:'${__from:date:iso}',to:'${__to:date:iso}'),useNormalizedEsInterval:!t),schema:segment,type:date_histogram)),params:(valueAxes:!((id:'ValueAxis-1',name:'LeftAxis-1',position:left,scale:(mode:normal,type:linear),show:!t,style:(),title:(text:'Sum+Request+Duration:+json.duration_s'),type:value)))))&
      _g=(time:(from:'${__from:date:iso}',to:'${__to:date:iso}'))
    |||),
  },
  testBuildElasticLinePercentileVizURL: {
    actual: elastic.buildElasticLinePercentileVizURL(
      index='sidekiq',
      filters=[
        {
          query: {
            match: {
              'json.shard': {
                query: 'throttled',
                type: 'phrase',
              },
            },
          },
        },
      ],
      splitSeries=false
    ),
    expect: joinMulti(|||
      https://log.gprd.gitlab.net/app/kibana#/visualize/create?
      type=line&
      indexPattern=AWNABDRwNDuQHTm2tH6l&
      _a=(filters:!((query:(match:(json.shard:(query:throttled,type:phrase))))),query:(language:kuery,query:''),vis:(aggs:!((enabled:!t,id:'1',params:(field:json.duration_s,percents:!(95)),schema:metric,type:percentiles),(enabled:!t,id:'2',params:(drop_partials:!t,extended_bounds:(),field:json.time,interval:auto,min_doc_count:1,scaleMetricValues:!f,timeRange:(from:'${__from:date:iso}',to:'${__to:date:iso}'),useNormalizedEsInterval:!t),schema:segment,type:date_histogram)),params:(valueAxes:!((id:'ValueAxis-1',name:'LeftAxis-1',position:left,scale:(mode:normal,type:linear),show:!t,style:(),title:(text:'p95+Request+Duration:+json.duration_s'),type:value)))))&
      _g=(time:(from:'${__from:date:iso}',to:'${__to:date:iso}'))
    |||),
  },

  testGetMatchersForPrometheusSelectorHashTranslation: {
    actual: elastic.getMatchersForPrometheusSelectorHash(
      'rails',
      {
        stage_group: 'source_code',
      }
    ),
    expect: [
      { meta: { key: 'query', type: 'custom', value: '{"bool": {"minimum_should_match": 1, "should": [{"match_phrase": {"json.meta.feature_category": "source_code_management"}}]}}' }, query: { bool: { minimum_should_match: 1, should: [{ match_phrase: { 'json.meta.feature_category': 'source_code_management' } }] } } },
    ],
  },
  testGetMatchersForPrometheusSelectorHashTranslationEq: {
    actual: elastic.getMatchersForPrometheusSelectorHash(
      'rails',
      {
        type: 'web',
        stage: { eq: 'cny' },
        // Prometheus regexes don't really translate to a matcher, but often they
        // only contain a single word instead of an array joined by `|`.
        feature_category: { re: 'pipeline_.*' },
      }
    ),
    expect: [
      { query: { match: { 'json.meta.feature_category': { query: 'pipeline_.*', type: 'phrase' } } } },
      { query: { match: { 'json.stage': { query: 'cny', type: 'phrase' } } } },
      { query: { match: { 'json.type': { query: 'web', type: 'phrase' } } } },
    ],
  },
  testGetMatchersForPrometheusSelectorHashTranslationNe: {
    actual: elastic.getMatchersForPrometheusSelectorHash(
      'rails',
      {
        stage: { ne: 'cny' },
      }
    ),
    expect: [
      { meta: { negate: true }, query: { match: { 'json.stage': { query: 'cny', type: 'phrase' } } } },
    ],
  },
  testGetMatchersForPrometheusSelectorHashTranslationArrays: {
    actual: elastic.getMatchersForPrometheusSelectorHash(
      'rails',
      {
        type: { oneOf: ['web', 'api'] },
        stage: { noneOf: ['cny'] },
      }
    ),
    expect: [
      { meta: { key: 'query', negate: true, type: 'custom', value: '{"bool": {"minimum_should_match": 1, "should": [{"match_phrase": {"json.stage": "cny"}}]}}' }, query: { bool: { minimum_should_match: 1, should: [{ match_phrase: { 'json.stage': 'cny' } }] } } },
      { meta: { key: 'query', type: 'custom', value: '{"bool": {"minimum_should_match": 1, "should": [{"match_phrase": {"json.type": "web"}}, {"match_phrase": {"json.type": "api"}}]}}' }, query: { bool: { minimum_should_match: 1, should: [{ match_phrase: { 'json.type': 'web' } }, { match_phrase: { 'json.type': 'api' } }] } } },
    ],
  },
})
