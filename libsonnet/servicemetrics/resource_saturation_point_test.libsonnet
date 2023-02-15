local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local test = import 'test.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

local testSaturationPoint = resourceSaturationPoint({
  title: 'Just a test',
  severity: 's4',
  horizontallyScalable: true,
  capacityPlanningStrategy: 'exclude',
  appliesTo: ['thanos', 'web', 'api'],
  description: |||
    Just testing
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

});

test.suite({
  testCapacityPlanningEnvironments: {
    actual: testSaturationPoint.capacityPlanningEnvironments,
    expect: ['gprd', 'thanos'],
  },
})
