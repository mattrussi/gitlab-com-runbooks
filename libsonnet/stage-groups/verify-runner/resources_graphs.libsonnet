local basic = import 'grafana/basic.libsonnet';

local runnersManagerMatching = import './runner_managers_matching.libsonnet';

local memoryUsage(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    title='Memory usage by instance',
    legendFormat='{{instance}}',
    format='percentunit',
    linewidth=2,
    fill=0,
    stack=false,
    query=runnersManagerMatching.formatQuery(|||
      instance:node_memory_utilization:ratio{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}
    |||, partition),
  );

local cpuUsage(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    title='CPU usage by instance',
    legendFormat='{{instance}}',
    format='percentunit',
    linewidth=2,
    fill=0,
    stack=false,
    query=runnersManagerMatching.formatQuery(|||
      instance:node_cpu_utilization:ratio{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}
    |||, partition),
  );

local fdsUsage(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    title='File Descriptiors usage by instance',
    legendFormat='{{instance}}',
    format='percentunit',
    linewidth=2,
    fill=0,
    stack=false,
    query=runnersManagerMatching.formatQuery(|||
      process_open_fds{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s,job="runners-manager"}
      /
      process_max_fds{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s,job="runners-manager"}
    |||, partition),
  );

local diskAvailable(partition=runnersManagerMatching.defaultPartition) =
  basic.timeseries(
    title='Disk available by instance and device',
    legendFormat='{{instance}} - {{device}}',
    format='percentunit',
    linewidth=2,
    fill=0,
    stack=false,
    query=runnersManagerMatching.formatQuery(|||
      instance:node_filesystem_avail:ratio{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s,fstype="ext4"}
    |||, partition),
  );

local iopsUtilization(partition=runnersManagerMatching.defaultPartition) =
  basic.multiTimeseries(
    title='IOPS',
    format='ops',
    linewidth=2,
    fill=0,
    stack=false,
    queries=[
      {
        legendFormat: '{{instance}} - writes',
        query: runnersManagerMatching.formatQuery(|||
          instance:node_disk_writes_completed:irate1m{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}
        |||, partition),
      },
      {
        legendFormat: '{{instance}} - reads',
        query: runnersManagerMatching.formatQuery(|||
          instance:node_disk_reads_completed:irate1m{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}
        |||, partition),
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

local networkUtilization(partition=runnersManagerMatching.defaultPartition) =
  basic.multiTimeseries(
    title='Network Utilization',
    format='bps',
    linewidth=2,
    fill=0,
    stack=false,
    queries=[
      {
        legendFormat: '{{instance}} - sent',
        query: runnersManagerMatching.formatQuery(|||
          sum by (instance) (
            rate(node_network_transmit_bytes_total{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}[$__rate_interval])
          )
        |||, partition),
      },
      {
        legendFormat: '{{instance}} - received',
        query: runnersManagerMatching.formatQuery(|||
          sum by (instance) (
            rate(node_network_receive_bytes_total{environment=~"$environment",stage=~"$stage",%(runnerManagersMatcher)s}[$__rate_interval])
          )
        |||, partition),
      },
    ],
  ) + {
    seriesOverrides+: [
      {
        alias: '/received/',
        transform: 'negative-Y',
      },
    ],
  };

{
  memoryUsage:: memoryUsage,
  cpuUsage:: cpuUsage,
  fdsUsage:: fdsUsage,
  diskAvailable:: diskAvailable,
  iopsUtilization:: iopsUtilization,
  networkUtilization:: networkUtilization,
}
