local basic = import 'grafana/basic.libsonnet';

local cpuUsage =
  basic.timeseries(
    title='CPU utilization by GKE node',
    legendFormat='{{instance}}',
    format='percentunit',
    linewidth=2,
    fill=0,
    stack=false,
    query=|||
      instance:node_cpu_utilization:ratio{job="gke-node", ci_environment=~"$ci_environment", environment=~"$environment", stage=~"$stage"}
    |||,
  );

local memoryUsage =
  basic.timeseries(
    title='Memory utilization by GKE node',
    legendFormat='{{instance}}',
    format='percentunit',
    linewidth=2,
    fill=0,
    stack=false,
    query=|||
      instance:node_memory_utilization:ratio{job="gke-node", ci_environment=~"$ci_environment", environment=~"$environment", stage=~"$stage"}
    |||,
  );

local diskAvailable =
  basic.timeseries(
    title='Disk available by instance and device',
    legendFormat='{{instance}} - {{device}}',
    format='percentunit',
    linewidth=2,
    fill=0,
    stack=false,
    query=|||
      min by(instance, device) (instance:node_filesystem_avail:ratio{job="gke-node", ci_environment=~"$ci_environment", environment=~"$environment", stage=~"$stage"})
    |||,
  );

local iopsUtilization =
  basic.multiTimeseries(
    title='IOPS',
    format='ops',
    linewidth=2,
    fill=0,
    stack=false,
    queries=[
      {
        legendFormat: '{{instance}} - writes',
        query: |||
          instance:node_disk_writes_completed:irate1m{job="gke-node", ci_environment=~"$ci_environment", environment=~"$environment", stage=~"$stage"}
        |||,
      },
      {
        legendFormat: '{{instance}} - reads',
        query: |||
          instance:node_disk_reads_completed:irate1m{job="gke-node", ci_environment=~"$ci_environment", environment=~"$environment", stage=~"$stage"}
        |||,
      },
    ],
  ) + {
    seriesOverrides+: [
      {
        alias: '/reads/',
        transform: 'negative-Y',
      },
    ],
  };

{
  cpuUsage:: cpuUsage,
  memoryUsage:: memoryUsage,
  diskAvailable:: diskAvailable,
  iopsUtilization:: iopsUtilization,
}
