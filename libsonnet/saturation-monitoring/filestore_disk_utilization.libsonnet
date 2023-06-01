local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local resourceSaturationPoint = (import 'servicemetrics/resource_saturation_point.libsonnet').resourceSaturationPoint;

{
  filestore_disk_utilization: resourceSaturationPoint({
    title: 'Filestore Disk Utilization',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findServicesWithTag(tag='filestore'),
    description: |||
      Filestore Disk utilization.

      See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-file for
      more details
    |||,
    grafana_dashboard_uid: 'sat_filestore_disk',
    resourceLabels: ['instance_name'],
    burnRatePeriod: '5m',
    staticLabels: {
      type: 'monitoring',
      tier: 'inf',
      stage: 'main',
    },
    query: |||
      avg_over_time(stackdriver_filestore_instance_file_googleapis_com_nfs_server_used_bytes_percent{%(selector)s}[%(rangeInterval)s]) / 100
    |||,
    slos: {
      soft: 0.85,
      hard: 0.90,
    },
  }),
}
