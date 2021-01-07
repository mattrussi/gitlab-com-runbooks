local elastic = import 'elasticsearch_links.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

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
    expect: 'https://log.gprd.gitlab.net/app/kibana#/discover?' +
            "_a=(columns:!(json.class,json.queue,json.meta.project,json.job_status,json.scheduling_latency_s,json.duration_s),filters:!((query:(match:(json.shard:(query:throttled,type:phrase))))),index:'AWNABDRwNDuQHTm2tH6l',query:(language:kuery,query:''))" + '&' +
            "_g=(time:(from:'${__from:date:iso}',to:'${__to:date:iso}'))",
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
    expect: 'https://log.gprd.gitlab.net/app/kibana#/visualize/create?' +
            'type=line' + '&' +
            'indexPattern=AWNABDRwNDuQHTm2tH6l' + '&' +
            "_a=(filters:!((query:(match:(json.shard:(query:throttled,type:phrase))))),query:(language:kuery,query:''),vis:(aggs:!((enabled:!t,id:'1',params:(),schema:metric,type:count),(enabled:!t,id:'2',params:(drop_partials:!t,extended_bounds:(),field:json.time,interval:auto,min_doc_count:1,scaleMetricValues:!f,timeRange:(from:'${__from:date:iso}',to:'${__to:date:iso}'),useNormalizedEsInterval:!t),schema:segment,type:date_histogram))))" + '&' +
            "_g=(time:(from:'${__from:date:iso}',to:'${__to:date:iso}'))",
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
    expect: 'https://log.gprd.gitlab.net/app/kibana#/visualize/create?' +
            'type=line' + '&' +
            'indexPattern=AWNABDRwNDuQHTm2tH6l' + '&' +
            "_a=(filters:!((query:(match:(json.shard:(query:throttled,type:phrase))))),query:(language:kuery,query:''),vis:(aggs:!((enabled:!t,id:'1',params:(field:json.duration_s),schema:metric,type:sum),(enabled:!t,id:'2',params:(drop_partials:!t,extended_bounds:(),field:json.time,interval:auto,min_doc_count:1,scaleMetricValues:!f,timeRange:(from:'${__from:date:iso}',to:'${__to:date:iso}'),useNormalizedEsInterval:!t),schema:segment,type:date_histogram)),params:(valueAxes:!((id:'ValueAxis-1',name:'LeftAxis-1',position:left,scale:(mode:normal,type:linear),show:!t,style:(),title:(text:'Sum+Request+Duration:+json.duration_s'),type:value)))))" + '&' +
            "_g=(time:(from:'${__from:date:iso}',to:'${__to:date:iso}'))",
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
    expect: 'https://log.gprd.gitlab.net/app/kibana#/visualize/create?' +
            'type=line' + '&' +
            'indexPattern=AWNABDRwNDuQHTm2tH6l' + '&' +
            "_a=(filters:!((query:(match:(json.shard:(query:throttled,type:phrase))))),query:(language:kuery,query:''),vis:(aggs:!((enabled:!t,id:'1',params:(field:json.duration_s,percents:!(95)),schema:metric,type:percentiles),(enabled:!t,id:'2',params:(drop_partials:!t,extended_bounds:(),field:json.time,interval:auto,min_doc_count:1,scaleMetricValues:!f,timeRange:(from:'${__from:date:iso}',to:'${__to:date:iso}'),useNormalizedEsInterval:!t),schema:segment,type:date_histogram)),params:(valueAxes:!((id:'ValueAxis-1',name:'LeftAxis-1',position:left,scale:(mode:normal,type:linear),show:!t,style:(),title:(text:'p95+Request+Duration:+json.duration_s'),type:value)))))" + '&' +
            "_g=(time:(from:'${__from:date:iso}',to:'${__to:date:iso}'))",
  },
})
