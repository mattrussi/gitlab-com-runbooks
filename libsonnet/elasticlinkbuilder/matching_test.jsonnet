local matching = import 'matching.libsonnet';
local test = import 'test.libsonnet';
test.suite({
  testMatcherFilter: {
    actual: matching.matcher('fieldName', 'test'),
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
    actual: matching.matcher('fieldName', ['hello', 'world']),
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
    actual: matching.matchers({
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
})
