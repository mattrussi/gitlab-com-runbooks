local templates = import 'grafana/templates.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local basic = import 'runbooks/libsonnet/grafana/basic.libsonnet';

local row = grafana.row;

{
  _runnerManagerTemplate:: $._config.templates.runnerManager,

  grafanaDashboards+:: {
    'hosted-runner-nodes.json':
      basic.dashboard(
        title='%s Nodes' % $._config.dashboardName,
        tags=$._config.dashboardTags,
        editable=true,
        includeStandardEnvironmentAnnotations=false,
        includeEnvironmentTemplate=false,
        defaultDatasource=$._config.prometheusDatasource
      )
      .addTemplate($._runnerManagerTemplate)
      .addTemplate(
        {
          name: 'shard',
          type: 'query',
          query: 'label_values(node_uname_info{type="hosted-runners"},shard)',
          includeAll: false,
          refresh: 1,
        }
      )
      .addTemplate(
        {
          name: 'service',
          type: 'query',
          query: 'label_values(node_uname_info{type="hosted-runners", shard="$shard"},service)',
          includeAll: false,
          refresh: 1,
        }
      )
      .addTemplate(
        {
          name: 'instance',
          type: 'query',
          query: 'label_values(node_uname_info{type="hosted-runners", service="$service", shard="$shard"},instance)',
          label: 'Instance',
          refresh: 2,
        }
      )
      .addPanel(
        row.new(title='CPU'),
        gridPos={ h: 1, w: 24, x: 0, y: 0 }
      )
      .addPanel(
        basic.timeseries(
          title='CPU Usage',
          query=|||
            (
              (1 - sum without (mode) (rate(node_cpu_seconds_total{mode=~"idle|iowait|steal", instance="$instance"}[$__rate_interval])))
              / ignoring(cpu) group_left
              count without (cpu, mode) (node_cpu_seconds_total{mode="idle", instance="$instance"})
            )
          |||,
          legendFormat='CPU #{{cpu}}',
          format='percentunit',
          fill=10,
          min=0,
          max=1,
          stack=true,
          stableId='node-cpu-usage'
        ),
        gridPos={ h: 7, w: 12, x: 0, y: 1 }
      )
      .addPanel(
        basic.multiTimeseries(
          title='Load Average',
          queries=[
            {
              query: 'node_load1{instance="$instance"}',
              legendFormat: '1m load average',
            },
            {
              query: 'node_load5{instance="$instance"}',
              legendFormat: '5m load average',
            },
            {
              query: 'node_load15{instance="$instance"}',
              legendFormat: '15m load average',
            },
            {
              query: 'count(node_cpu_seconds_total{instance="$instance", mode="idle"})',
              legendFormat: 'logical cores',
            },
          ],
          format='short',
          min=0,
          fill=0,
          stableId='node-load-average'
        ),
        gridPos={ h: 7, w: 12, x: 12, y: 1 }
      )
      .addPanel(
        row.new(title='Memory'),
        gridPos={ h: 1, w: 24, x: 0, y: 8 }
      )
      .addPanel(
        basic.multiTimeseries(
          title='Memory Usage',
          queries=[
            {
              query: |||
                (
                  node_memory_MemTotal_bytes{instance="$instance"}
                  -
                  node_memory_MemFree_bytes{instance="$instance"}
                  -
                  node_memory_Buffers_bytes{instance="$instance"}
                  -
                  node_memory_Cached_bytes{instance="$instance"}
                )
              |||,
              legendFormat: 'memory used',
            },
            {
              query: 'node_memory_Buffers_bytes{instance="$instance"}',
              legendFormat: 'memory buffers',
            },
            {
              query: 'node_memory_Cached_bytes{instance="$instance"}',
              legendFormat: 'memory cached',
            },
            {
              query: 'node_memory_MemFree_bytes{instance="$instance"}',
              legendFormat: 'memory free',
            },
          ],
          format='bytes',
          min=0,
          fill=10,
          stack=true,
          stableId='node-memory-usage'
        ),
        gridPos={ h: 7, w: 18, x: 0, y: 9 }
      )
      .addPanel(
        basic.statPanel(
          title='Memory Usage',
          panelTitle='Memory Usage',
          query=|||
            100 -
            (
              avg(node_memory_MemAvailable_bytes{instance="$instance"}) /
              avg(node_memory_MemTotal_bytes{instance="$instance"})
              * 100
            )
          |||,
          unit='percent',
          min=0,
          max=100,
          color=[
            { color: 'green', value: null },
            { color: 'orange', value: 80 },
            { color: 'red', value: 90 },
          ],
          graphMode='gauge',
          stableId='node-memory-usage-gauge',
          decimals=0
        ),
        gridPos={ h: 7, w: 6, x: 18, y: 9 }
      )
      .addPanel(
        row.new(title='Disk'),
        gridPos={ h: 1, w: 24, x: 0, y: 16 }
      )
      .addPanel(
        basic.multiTimeseries(
          title='Disk I/O',
          queries=[
            {
              query: 'rate(node_disk_read_bytes_total{instance="$instance", device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)"}[$__rate_interval])',
              legendFormat: '{{device}} read',
            },
            {
              query: 'rate(node_disk_written_bytes_total{instance="$instance", device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)"}[$__rate_interval])',
              legendFormat: '{{device}} written',
            },
            {
              query: 'rate(node_disk_io_time_seconds_total{instance="$instance", device=~"(/dev/)?(mmcblk.p.+|nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|md.+|dasd.+)"}[$__rate_interval])',
              legendFormat: '{{device}} io time',
            },
          ],
          format='Bps',
          fill=0,
          stableId='node-disk-io'
        ),
        gridPos={ h: 7, w: 12, x: 0, y: 17 }
      )
      .addPanel(
        basic.timeseries(
          title='Disk Space Usage',
          description='Disk space usage per mount point',
          query=|||
            max by (mountpoint) (
              node_filesystem_size_bytes{instance="$instance", fstype!="", mountpoint!=""} -
              node_filesystem_avail_bytes{instance="$instance", fstype!="", mountpoint!=""}
            )
            /
            max by (mountpoint) (
              node_filesystem_size_bytes{instance="$instance", fstype!="", mountpoint!=""}
            )
          |||,
          legendFormat='{{mountpoint}}',
          format='percentunit',
          min=0,
          max=1,
          decimals=1,
          stableId='node-disk-space-usage'
        ),
        gridPos={ h: 7, w: 12, x: 12, y: 17 }
      )
      .addPanel(
        row.new(title='Network'),
        gridPos={ h: 1, w: 24, x: 0, y: 24 }
      )
      .addPanel(
        basic.timeseries(
          title='Network Received',
          description='Network received (bits/s)',
          query='rate(node_network_receive_bytes_total{instance="$instance", device!~"lo|docker"}[$__rate_interval]) * 8',
          legendFormat='{{device}}',
          format='bps',
          min=0,
          stableId='node-network-received'
        ),
        gridPos={ h: 7, w: 12, x: 0, y: 25 }
      )
      .addPanel(
        basic.timeseries(
          title='Network Transmitted',
          description='Network transmitted (bits/s)',
          query='rate(node_network_transmit_bytes_total{instance="$instance", device!~"lo|docker"}[$__rate_interval]) * 8',
          legendFormat='{{device}}',
          format='bps',
          min=0,
          stableId='node-network-transmitted'
        ),
        gridPos={ h: 7, w: 12, x: 12, y: 25 }
      ),
  },
}
