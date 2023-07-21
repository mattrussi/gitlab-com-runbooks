local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local saturation = import 'servicemetrics/saturation-resources.libsonnet';
local manifest = import 'tamland.jsonnet';
local test = import 'test.libsonnet';

local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

local saturationPoints = {
  michael_scott: resourceSaturationPoint({
    title: 'Michael Scott',
    severity: 's4',
    horizontallyScalable: true,
    capacityPlanning: {
      strategy: 'exclude',
    },
    appliesTo: ['thanos', 'web', 'api'],
    description: |||
      Just Mr Tamland chart
    |||,
    grafana_dashboard_uid: 'just testing',
    resourceLabels: ['name'],
    query: |||
      memory_used_bytes{area="heap", %(selector)s}
      /
      memory_max_bytes{area="heap", %(selector)s}
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),
  jimbo: resourceSaturationPoint({
    title: 'Jimbo',
    severity: 's4',
    horizontallyScalable: true,
    capacityPlanning: {
      strategy: 'exclude',
    },
    appliesTo: ['thanos', 'redis'],
    description: |||
      Just Mr Jimbo
    |||,
    grafana_dashboard_uid: 'just testing',
    resourceLabels: ['name'],
    query: |||
      memory_used_bytes{area="heap", %(selector)s}
      /
      memory_max_bytes{area="heap", %(selector)s}
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),
};

test.suite({
  testHasDefaultEnvironment: {
    actual: manifest,
    expectThat: {
      result: std.objectHas(self.actual.defaults, 'environment') == true,
      description: 'Expect object to have serviceCatalog field',
    },
  },
  testHasSaturationPoints: {
    actual: manifest,
    expectThat: {
      result: std.objectHas(self.actual, 'saturationPoints') == true,
      description: 'Expect object to have saturationPoints field',
    },
  },
  testHasServices: {
    actual: manifest,
    expectThat: {
      result: std.objectHas(self.actual, 'services') == true,
      description: 'Expect object to have serviceCatalog field',
    },
  },
  testHasServiceCatalogTeamsField: {
    actual: manifest,
    expectThat: {
      result: std.objectHas(self.actual, 'teams') == true,
      description: 'Expect object to have serviceCatalog.teams field',
    },
  },
  testHasServiceCatalogTeamsFields: {
    actual: manifest,
    expectThat: {
      result: std.sort(std.objectFields(self.actual.teams[0])) == std.sort(['name', 'label', 'manager']),
      description: 'Expect object to have serviceCatalog.teams fields',
    },
  },
})
