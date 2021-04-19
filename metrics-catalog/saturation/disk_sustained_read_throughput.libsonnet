local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local diskSaturationHelpers = import 'helpers/disk_saturation_helpers.libsonnet';

{
  disk_sustained_read_throughput: resourceSaturationPoint({
    title: 'Disk Sustained Read Throughput Utilization per Node',
    severity: 's3',
    horizontallyScalable: true,
    appliesTo: diskSaturationHelpers.diskPerformanceSensitiveServices,
    description: |||
      Disk sustained read throughput utilization per node.
    |||,
    grafana_dashboard_uid: 'sat_disk_sus_read_throughput',
    resourceLabels: ['fqdn', 'device'],
    query: |||
      rate(node_disk_read_bytes_total{device!="sda", %(selector)s}[%(rangeInterval)s])
      /
      node_disk_max_read_bytes_seconds{device!="sda", %(selector)s}
    |||,
    burnRatePeriod: '20m',
    slos: {
      soft: 0.70,
      hard: 0.80,
      alertTriggerDuration: '25m',
    },
  }),
}
