local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  disk_space: resourceSaturationPoint({
    title: 'Disk Space Utilization per Device per Node',
    severity: 's2',
    horizontallyScalable: true,
    appliesTo: { allExcept: ['nat', 'waf', 'bastion'], default: 'gitaly' },
    description: |||
      Disk space utilization per device per node.
    |||,
    grafana_dashboard_uid: 'sat_disk_space',
    resourceLabels: ['fqdn', 'device'],
    query: |||
      (
        1 - instance:node_filesystem_avail:ratio{fstype=~"ext.|xfs", %(selector)s}
      )
    |||,
    slos: {
      soft: 0.85,
      hard: 0.90,
      alertTriggerDuration: '15m',
    },
  }),
}
