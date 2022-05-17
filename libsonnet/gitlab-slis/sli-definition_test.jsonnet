local sliDefinition = import './sli-definition.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';
local objects = import 'utils/objects.libsonnet';

local validSLI = {
  name: 'hello_sli',
  kinds: [sliDefinition.apdexKind],
  description: 'an SLI counting hellos',
  significantLabels: ['world'],
  featureCategory: 'error_budgets',
};

test.suite({
  testNew: {
    actual: sliDefinition.new(validSLI),
    expect: {
      name: 'hello_sli',
      kinds: [sliDefinition.apdexKind],
      featureCategory: 'error_budgets',
      description: 'an SLI counting hellos',
      significantLabels: ['world'],
      inRecordingRuleRegistry: false,
      totalCounterName: 'gitlab_sli:hello_sli_apdex:total',
      apdexTotalCounterName: 'gitlab_sli:hello_sli_apdex:total',
      apdexSuccessCounterName: 'gitlab_sli:hello_sli_apdex:success_total',
      recordingRuleMetrics: ['gitlab_sli:hello_sli_apdex:total', 'gitlab_sli:hello_sli_apdex:success_total'],
    },
  },

  testNewWithoutFeatureCategory: {
    local sli = objects.objectWithout(validSLI, 'featureCategory') {
      significantLabels: ['world', 'feature_category'],
    },
    actual: sliDefinition.new(sli),
    expect: {
      name: 'hello_sli',
      kinds: [sliDefinition.apdexKind],
      featureCategory: 'featureCategoryFromSourceMetrics',
      description: 'an SLI counting hellos',
      significantLabels: ['world', 'feature_category'],
      inRecordingRuleRegistry: false,
      totalCounterName: 'gitlab_sli:hello_sli_apdex:total',
      apdexTotalCounterName: 'gitlab_sli:hello_sli_apdex:total',
      apdexSuccessCounterName: 'gitlab_sli:hello_sli_apdex:success_total',
      recordingRuleMetrics: ['gitlab_sli:hello_sli_apdex:total', 'gitlab_sli:hello_sli_apdex:success_total'],
    },
  },

  local validate(sli) = sliDefinition._sliValidator.isValid(sli),

  testFeatureCategoryUnknown: {
    local sli = validSLI { featureCategory: 'not a feature' },
    actual: validate(sli),
    expect: false,
  },

  testFeatureCategoryNotOwned: {
    local sli = validSLI { featureCategory: 'not_owned' },
    actual: validate(sli),
    expect: true,
  },

  testFeatureCategoryNull: {
    local sli = validSLI { featureCategory: null },
    actual: validate(sli),
    expect: false,
  },

  testFeatureCategoryMissing: {
    local sli = objects.objectWithout(validSLI, 'featureCategory'),
    actual: validate(sli),
    expect: false,
  },

  testNewMultipleKinds: {
    actual: sliDefinition.new(validSLI {
      kinds: [sliDefinition.apdexKind, sliDefinition.errorRateKind],
    }),
    expect: {
      name: 'hello_sli',
      kinds: [sliDefinition.apdexKind, sliDefinition.errorRateKind],
      description: 'an SLI counting hellos',
      significantLabels: ['world'],
      featureCategory: 'error_budgets',
      inRecordingRuleRegistry: false,
      totalCounterName: 'gitlab_sli:hello_sli:total',
      apdexTotalCounterName: 'gitlab_sli:hello_sli_apdex:total',
      apdexSuccessCounterName: 'gitlab_sli:hello_sli_apdex:success_total',
      errorTotalCounterName: 'gitlab_sli:hello_sli:total',
      errorCounterName: 'gitlab_sli:hello_sli:error_total',
      recordingRuleMetrics: ['gitlab_sli:hello_sli_apdex:total', 'gitlab_sli:hello_sli_apdex:success_total', 'gitlab_sli:hello_sli:total', 'gitlab_sli:hello_sli:error_total'],
    },
  },

  testNewInvalidKind: {
    actual: validate(validSLI { kinds: ['foo_rate'] }),
    expect: false,
  },

  testNewNoKind: {
    actual: validate(validSLI { kinds: [] }),
    expect: false,
  },
})
