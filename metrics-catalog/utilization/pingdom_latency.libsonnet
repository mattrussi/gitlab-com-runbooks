local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local metricsCatalogEntries = import 'servicemetrics/metrics-catalog.libsonnet';
local utilizationMetric = metricsCatalog.utilizationMetric;

{
  pingdom_latency: utilizationMetric({
    title: 'Pingdom Request latency',
    // Measured in seconds.
    //
    // Sourced from https://github.com/grafana/grafana/blob/main/packages/grafana-data/src/valueFormats/categories.ts
    unit: 's',
    appliesTo: metricsCatalogEntries.findServicesWithTag(tag='monitored::pingdom'),

    // This is emitted by the
    emittedBy: ['pingdom'],
    description: |||
      Tracks the request latency observed from Pingdom checks
    |||,
    resourceLabels: ['hostname', 'name'],
    query: |||
      sum by (%(aggregationLabels)s) (
        pingdom_uptime_response_time_seconds{%(selector)s}
      )
    |||,
  }),
}
