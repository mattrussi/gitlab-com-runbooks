local mappingWithOverride = import 'stage-group-mapping-with-overrides.jsonnet';
local test = import 'test.libsonnet';

test.suite({
  testLookupByInexistentGroup: {
    actual: std.get(mappingWithOverride, 'asdf', null),
    expect: null,
  },
  testLookupByUntouchedGroup: {
    actual: mappingWithOverride.scalability,
    expectContains: {
      stage: 'platforms',
      feature_categories: [
        'scalability',
        'error_budgets',
        'infrastructure_cost_data',
        'capacity_planning',
        'redis',
        'rate_limiting',
      ],
    },
  },
  testLookupByMergeGroup: {
    actual: mappingWithOverride.gitaly,
    expectContains: {
      stage: 'data_access',
      feature_categories: ['gitaly', 'git'],  // feature categories collected by source group(s)
    },
  },
})
