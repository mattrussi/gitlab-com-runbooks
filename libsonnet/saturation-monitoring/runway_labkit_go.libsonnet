local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

// Copied from go_goroutines
{
  runway_labkit_go_goroutines: resourceSaturationPoint({
    title: 'Go goroutines Utilization per instance',
    severity: 's4',
    dangerouslyThanosEvaluated: true,
    horizontallyScalable: true,
    appliesTo: std.setInter(
      std.set(metricsCatalog.findServicesWithTag(tag='golang')),
      std.set(metricsCatalog.findRunwayProvisionedServices())
    ),
    description: |||
      Go goroutines utilization per node.

      Goroutines leaks can cause memory saturation which can cause service degradation.

      A limit of 250k goroutines is very generous, so if a service exceeds this limit,
      it's a sign of a leak and it should be dealt with.
    |||,
    grafana_dashboard_uid: 'sat_runway_labkit_go_goroutines',
    resourceLabels: ['region', 'instance'],
    queryFormatConfig: {
      maxGoroutines: 250000,
    },
    query: |||
      sum by (%(aggregationLabels)s) (
        go_goroutines{%(selector)s}
      )
      /
      %(maxGoroutines)g
    |||,
    slos: {
      soft: 0.90,
      hard: 0.98,
    },
  }),
}
