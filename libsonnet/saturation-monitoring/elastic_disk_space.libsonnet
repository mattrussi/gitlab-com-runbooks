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
    resourceLabels: ['host'],
    query: |||
      sum by (%(aggregationLabels)s) (
        (elasticsearch_filesystem_data_size_bytes{%(selector)s} - elasticsearch_filesystem_data_free_bytes{%(selector)s})
      )
      /
      sum by (%(aggregationLabels)s) (
        elasticsearch_filesystem_data_size_bytes{%(selector)s}
      )
    |||,
    slos: {
      soft: 0.70,
      hard: 0.90,  // Temporarily increased SLO to 90% to wait for index rollover deletion after spikes. Incident issue: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8422
    },
  }),
}
