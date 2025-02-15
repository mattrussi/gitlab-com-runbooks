local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  elastic_disk_space: resourceSaturationPoint({
    title: 'Disk Utilization Overall',
    severity: 's2',
    horizontallyScalable: true,
    appliesTo: ['logging', 'search'],
    description: |||
      Disk utilization per device per node.
    |||,
    grafana_dashboard_uid: 'sat_elastic_disk_space',
    resourceLabels: [],
    query: |||
      1 - (
        sum by (%(aggregationLabels)s) (
          (elasticsearch_filesystem_data_free_bytes{%(selector)s})
        )
        /
        sum by (%(aggregationLabels)s) (
          elasticsearch_filesystem_data_size_bytes{%(selector)s}
        )
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),
}
