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
    grafana_dashboard_uid: 'sat_filestore_utilization',
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
  filestore_disk_read_iops_saturation: resourceSaturationPoint({
    title: 'Filestore Disk Read IOPS Saturation',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findServicesWithTag(tag='filestore'),
    description: |||
      Filestore Disk Read IOPS Saturation.

      See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-file for
      more details
    |||,
    grafana_dashboard_uid: 'sat_filestore_read_iops',
    resourceLabels: ['instance_name'],
    burnRatePeriod: '5m',
    staticLabels: {
      type: 'monitoring',
      tier: 'inf',
      stage: 'main',
    },
    query: |||
      (stackdriver_filestore_instance_file_googleapis_com_nfs_server_read_ops_count / 60)
      /
      600
    |||,
    slos: {
      soft: 0.85,
      hard: 0.9,
    },
  }),
  filestore_disk_write_iops_saturation: resourceSaturationPoint({
    title: 'Filestore Disk Write IOPS Saturation',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findServicesWithTag(tag='filestore'),
    description: |||
      Filestore Disk Write IOPS Saturation.

      See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-file for
      more details
    |||,
    grafana_dashboard_uid: 'sat_filestore_write_iops',
    resourceLabels: ['instance_name'],
    burnRatePeriod: '5m',
    staticLabels: {
      type: 'monitoring',
      tier: 'inf',
      stage: 'main',
    },
    query: |||
      (stackdriver_filestore_instance_file_googleapis_com_nfs_server_write_ops_count / 60)
      /
      1000
    |||,
    slos: {
      soft: 0.85,
      hard: 0.9,
    },
  }),
  filestore_disk_read_throughput_saturation: resourceSaturationPoint({
    title: 'Filestore Disk Read Throughput Saturation',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findServicesWithTag(tag='filestore'),
    description: |||
      Filestore Disk Read Throughput Saturation.

      See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-file for
      more details
    |||,
    grafana_dashboard_uid: 'sat_filestore_read_throughput',
    resourceLabels: ['instance_name'],
    burnRatePeriod: '5m',
    staticLabels: {
      type: 'monitoring',
      tier: 'inf',
      stage: 'main',
    },
    query: |||
      (stackdriver_filestore_instance_file_googleapis_com_nfs_server_read_bytes_count / 60)
      /
      100000000
    |||,
    slos: {
      soft: 0.85,
      hard: 0.9,
    },
  }),

  filestore_disk_write_throughput_saturation: resourceSaturationPoint({
    title: 'Filestore Disk Write Throughput Saturation',
    severity: 's4',
    horizontallyScalable: true,
    appliesTo: metricsCatalog.findServicesWithTag(tag='filestore'),
    description: |||
      Filestore Disk Write Throughput Saturation.

      See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-file for
      more details
    |||,
    grafana_dashboard_uid: 'sat_filestore_write_throughput',
    resourceLabels: ['instance_name'],
    burnRatePeriod: '5m',
    staticLabels: {
      type: 'monitoring',
      tier: 'inf',
      stage: 'main',
    },
    query: |||
      (stackdriver_filestore_instance_file_googleapis_com_nfs_server_write_bytes_count / 60)
      /
      100000000
    |||,
    slos: {
      soft: 0.85,
      hard: 0.9,
    },
  }),
}
