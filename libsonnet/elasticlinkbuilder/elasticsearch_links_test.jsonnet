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
})
