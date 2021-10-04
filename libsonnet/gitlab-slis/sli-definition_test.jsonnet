local sliDefinition = import './sli-definition.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testNew: {
    actual: sliDefinition.new({
      name: 'hello_sli',
      kind: 'apdex',
      significantLabels: ['world'],
    }),
    expect: {
      name: 'hello_sli',
      kind: 'apdex',
      significantLabels: ['world'],
      totalCounterName: 'gitlab_sli:hello_sli:total',
      successCounterName: 'gitlab_sli:hello_sli:success_total',
    },
  },
})
