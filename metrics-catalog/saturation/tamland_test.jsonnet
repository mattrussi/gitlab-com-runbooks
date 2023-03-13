local tamlandSaturation = import 'tamland.jsonnet';
local test = import 'test.libsonnet';

test.suite({
  testHasServiceEnvMappingObject: {
    actual: tamlandSaturation,
    expectThat: {
      result: std.objectHas(self.actual, 'servicesEnvMapping') == true,
      description: 'Expect object to have servicesEnvMapping field',
    },
  },
  testServiceEnvMappingObjectNotEmpty: {
    actual: tamlandSaturation,
    expectThat: {
      result: std.length(self.actual.servicesEnvMapping) > 0,
      description: 'Expect servicesEnvMapping object to be not empty',
    },
  },
})
