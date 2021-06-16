local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;
local saturationHelpers = import 'helpers/saturation_helpers.libsonnet';

{
  disk_sustained_read_iops: resourceSaturationPoint({
    title: 'Disk Sustained Read IOPS Utilization per Node',
    severity: 's3',
    horizontallyScalable: true,
    appliesTo: saturationHelpers.diskPerformanceSensitiveServices,
    description: |||
      Disk sustained read IOPS utilization per node.
    |||,
    grafana_dashboard_uid: 'sat_disk_sus_read_iops',
    resourceLabels: ['fqdn', 'device'],
    query: |||
      rate(node_disk_reads_completed_total{device!="sda", %(selector)s}[%(rangeInterval)s])
      /
      node_disk_max_read_iops{device!="sda", %(selector)s}
    |||,
    burnRatePeriod: '20m',
    slos: {
      soft: 0.80,
      hard: 0.90,
      alertTriggerDuration: '25m',
    },
  }),
}
