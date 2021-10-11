local sliDefinition = import './sli-definition.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testNew: {
    actual: sliDefinition.new({
      name: 'hello_sli',
      kind: 'apdex',
      description: 'an SLI counting hellos',
      significantLabels: ['world'],
    }),
    expect: {
      name: 'hello_sli',
      kind: 'apdex',
      description: 'an SLI counting hellos',
      significantLabels: ['world'],
      totalCounterName: 'gitlab_sli:hello_sli:total',
      successCounterName: 'gitlab_sli:hello_sli:success_total',
      recordingRuleMetrics: ['gitlab_sli:hello_sli:total', 'gitlab_sli:hello_sli:success_total'],
    },
  },
})
