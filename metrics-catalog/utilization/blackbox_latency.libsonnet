local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local metricsCatalogEntries = import 'servicemetrics/metrics-catalog.libsonnet';
local utilizationMetric = metricsCatalog.utilizationMetric;

{
  blackbox_request_latency: utilizationMetric({
    title: 'BlackBox Observed Request latency',
    // Measured in seconds.
    //
    // Sourced from https://github.com/grafana/grafana/blob/main/packages/grafana-data/src/valueFormats/categories.ts
    unit: 's',
    appliesTo: metricsCatalogEntries.findServicesWithTag(tag='monitored::blackbox'),

    // This is emitted by the
    emittedBy: ['blackbox'],
    description: |||
      Tracks the request latency observed from BlackBox exporter checks
    |||,
    resourceLabels: ['instance', 'phase'],
    query: |||
      sum by (%(aggregationLabels)s) (
        probe_http_duration_seconds{%(selector)s}
      )
    |||,
  }),
}
