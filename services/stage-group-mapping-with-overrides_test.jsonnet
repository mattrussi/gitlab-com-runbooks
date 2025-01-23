local mappingWithOverride = import 'stage-group-mapping-with-overrides.jsonnet';
local test = import 'test.libsonnet';

test.suite({
  testLookupByInexistentGroup: {
    actual: std.get(mappingWithOverride, 'asdf', null),
    expect: null,
  },
  testLookupByUntouchedGroup: {
    actual: mappingWithOverride.observability,
    expectContains: {
      stage: 'production_engineering',
      feature_categories: [
        'error_budgets',
        'infra_cost_data',
        'capacity_planning',
        'scalability',
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
