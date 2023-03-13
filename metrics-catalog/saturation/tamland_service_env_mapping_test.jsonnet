local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local tamlandServiceEnvMapping = import 'tamland_service_env_mapping.libsonnet';
local test = import 'test.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

local saturationPoints = {
  michael_scott: resourceSaturationPoint({
    title: 'Michael Scott',
    severity: 's4',
    horizontallyScalable: true,
    capacityPlanningStrategy: 'exclude',
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
    capacityPlanningStrategy: 'exclude',
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
  testUniqServices: {
    actual: tamlandServiceEnvMapping.uniqServices(saturationPoints),
    expect: ['api', 'redis', 'thanos', 'web'],
  },
  testservicesEnvMapping: {
    actual: tamlandServiceEnvMapping.servicesEnvMapping(['api', 'redis', 'thanos', 'web']),
    expect: {
      api: 'gprd',
      redis: 'gprd',
      thanos: 'thanos',
      web: 'gprd',
    },
  },
})
