local mapping = import './tamland_service_env_mapping.libsonnet';
local saturation = import 'servicemetrics/saturation-resources.libsonnet';
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
  testHasServiceCatalogObject: {
    actual: tamlandSaturation,
    expectThat: {
      result: std.objectHas(self.actual, 'serviceCatalog') == true,
      description: 'Expect object to have serviceCatalog field',
    },
  },
  testHasServiceCatalogServicesField: {
    actual: tamlandSaturation,
    expectThat: {
      result: std.objectHas(self.actual.serviceCatalog, 'services') == true,
      description: 'Expect object to have serviceCatalog.services field',
    },
  },
  testHasServiceCatalogServicesFields: {
    actual: tamlandSaturation,
    expectThat: {
      result: std.sort(std.objectFields(self.actual.serviceCatalog.services[0])) == std.sort(['name', 'label', 'owner', 'capacity_planning']),
      description: 'Expect object to have serviceCatalog.services fields',
    },
  },
  testHasServiceCatalogTeamsField: {
    actual: tamlandSaturation,
    expectThat: {
      result: std.objectHas(self.actual.serviceCatalog, 'teams') == true,
      description: 'Expect object to have serviceCatalog.teams field',
    },
  },
  testHasServiceCatalogTeamsFields: {
    actual: tamlandSaturation,
    expectThat: {
      result: std.sort(std.objectFields(self.actual.serviceCatalog.teams[0])) == std.sort(['name', 'label', 'manager']),
      description: 'Expect object to have serviceCatalog.teams fields',
    },
  },
  testServiceCatalogServicesSubset: {
    actual: tamlandSaturation,
    expectThat: {
      result:
        local metricsCatalogServices = std.sort(mapping.uniqServices(saturation));
        local serviceCatalogServices = std.sort(
          std.map(
            function(service)
              service.name
            , self.actual.serviceCatalog.services
          )
        );
        local unknownServices = std.setDiff(metricsCatalogServices, serviceCatalogServices);
        std.length(unknownServices) == 0,
      description: 'Expected metricsCatalog services to be subset of serviceCatalog services',
    },
  },
})
