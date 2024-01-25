local separateMimirRecordingFiles = (import './separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local test = import 'test.libsonnet';
local serviceDefinition = import 'servicemetrics/service_definition.libsonnet';

local fakeMetricsConfig = {
  separateMimirRecordingSelectors: {
    'gitlab-ops': {
      selector: { env: 'ops' },
      envName: 'ops',
    },
    'gitlab-gprd': {
      selector: { env: 'gprd' },
      envName: 'gprd',
    },
    'gitlab-others': {
      selector: { env: { noneOf: ['ops', 'gprd'] } },
      envName: 'others',
    },
  },
};

local fakeService = serviceDefinition.serviceDefinition({
  type: 'foo',
});

test.suite({
  testSeparateMimirRecordingFiles: {
    actual: separateMimirRecordingFiles(
      function(service, selector, extraArgs) { rule_file_basename: selector },
      serviceDefinition=fakeService,
      metricsConfig=fakeMetricsConfig
    ),
    expect: {
      'gitlab-ops/ops/foo/gitlab-ops-ops-foo-rule_file_basename.yml': { env: 'ops' },
      'gitlab-gprd/gprd/foo/gitlab-gprd-gprd-foo-rule_file_basename.yml': { env: 'gprd' },
      'gitlab-others/others/foo/gitlab-others-others-foo-rule_file_basename.yml': { env: { noneOf: ['ops', 'gprd'] } },
    },
  },
  testSeparateMimirRecordingFilesWithoutService: {
    actual: separateMimirRecordingFiles(
      function(service, selector, extraArgs) { rule_file_basename: selector },
      metricsConfig=fakeMetricsConfig
    ),
    expect: {
      'gitlab-ops/ops/gitlab-ops-ops-rule_file_basename.yml': { env: 'ops' },
      'gitlab-gprd/gprd/gitlab-gprd-gprd-rule_file_basename.yml': { env: 'gprd' },
      'gitlab-others/others/gitlab-others-others-rule_file_basename.yml': { env: { noneOf: ['ops', 'gprd'] } },
    },
  },
})
