local periodicQueries = import './periodic-query.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testDefaults: {
    actual: periodicQueries.new({
      requestParams: {
        query: 'promql',
      },
      tenants: ['gitlab-gprd'],
    }),
    expect: {
      requestParams: {
        query: 'promql',
      },
      type: 'instant',
      tenants: ['gitlab-gprd'],
    },
  },
})
