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
      function(service, selector, extraArgs) { hello: selector },
      serviceDefinition=fakeService,
      metricsConfig=fakeMetricsConfig
    ),
    expect: {
      'gitlab-ops/ops/foo/hello.yml': { env: 'ops' },
      'gitlab-gprd/gprd/foo/hello.yml': { env: 'gprd' },
      'gitlab-others/others/foo/hello.yml': { env: { noneOf: ['ops', 'gprd'] } },
    },
  },
  testSeparateMimirRecordingFilesWithoutService: {
    actual: separateMimirRecordingFiles(
      function(service, selector, extraArgs) { hello: selector },
      metricsConfig=fakeMetricsConfig
    ),
    expect: {
      'gitlab-ops/ops/hello.yml': { env: 'ops' },
      'gitlab-gprd/gprd/hello.yml': { env: 'gprd' },
      'gitlab-others/others/hello.yml': { env: { noneOf: ['ops', 'gprd'] } },
    },
  },
})
