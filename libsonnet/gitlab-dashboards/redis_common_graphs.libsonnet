local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local processExporter = import 'gitlab-dashboards/process_exporter.libsonnet';

{
  clientPanels(serviceType, startRow, cluster=false)::
    local formatConfig = {
      selector: selectors.serializeHash({
        environment: '$environment',
        type: serviceType,
        [if cluster then 'shard']: { re: '$shard' },
      }),
    };

    layout.grid([
      basic.timeseries(
        title='Connected Clients',
        yAxisLabel='Clients',
        query=|||
          sum(avg_over_time(redis_connected_clients{%(selector)s}[$__interval])) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Blocked Clients',
        description='Blocked clients are waiting for a state change event using commands such as BLPOP. Blocked clients are not a sign of an issue on their own.',
        yAxisLabel='Blocked Clients',
        query=|||
          sum(avg_over_time(redis_blocked_clients{%(selector)s}[$__interval])) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Connections Received',
        yAxisLabel='Connections',
        query=|||
          sum(rate(redis_connections_received_total{%(selector)s}[$__interval])) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=2,
      ),
    ], cols=2, rowHeight=10, startRow=startRow),

  workload(serviceType, startRow, cluster=false)::
    local formatConfig = {
      serviceType: serviceType,
      primarySelectorSnippet: 'and on (instance) redis_instance_info{role="master"}',
      replicaSelectorSnippet: 'and on (instance) redis_instance_info{role="slave"}',
      selector: selectors.serializeHash({
        environment: '$environment',
        type: serviceType,
        [if cluster then 'shard']: { re: '$shard' },
      }),
    };
    layout.grid([
      basic.timeseries(
        title='Operation Rate - Primary',
        yAxisLabel='Operations/sec',
        query=|||
          sum(rate(redis_commands_total{%(selector)s}[$__interval]) %(primarySelectorSnippet)s ) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=1,
      ),
      basic.timeseries(
        title='Operation Rate - Replicas',
        yAxisLabel='Operations/sec',
        query=|||
          sum(rate(redis_commands_total{%(selector)s}[$__interval]) %(replicaSelectorSnippet)s ) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=1,
      ),
      basic.saturationTimeseries(
        title='Redis CPU per Node - Primary',
        description='redis is single-threaded. This graph shows maximum utilization across all cores on each host. Lower is better.',
        query=|||
          max(
            max_over_time(instance:redis_cpu_usage:rate1m{environment="$environment", type="%(serviceType)s"}[$__interval])
              %(primarySelectorSnippet)s
          ) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        interval='30s',
        intervalFactor=1,
      ),
      basic.saturationTimeseries(
        title='Redis CPU per Node - Replicas',
        description='redis is single-threaded. This graph shows maximum utilization across all cores on each host. Lower is better.',
        query=|||
          max(
            max_over_time(instance:redis_cpu_usage:rate1m{environment="$environment", type="%(serviceType)s"}[$__interval])
              %(replicaSelectorSnippet)s
          ) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        interval='30s',
        intervalFactor=1,
      ),
      basic.timeseries(
        title='Redis Network Out - Primary',
        format='Bps',
        query=|||
          sum(rate(redis_net_output_bytes_total{%(selector)s}[$__interval])
           %(primarySelectorSnippet)s
          ) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Redis Network Out - Replicas',
        format='Bps',
        query=|||
          sum(rate(redis_net_output_bytes_total{%(selector)s}[$__interval])
           %(replicaSelectorSnippet)s
          ) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Redis Network In - Primary',
        format='Bps',
        query=|||
          sum(rate(redis_net_input_bytes_total{%(selector)s}[$__interval])
            %(primarySelectorSnippet)s
          ) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Redis Network In - Replicas',
        format='Bps',
        query=|||
          sum(rate(redis_net_input_bytes_total{%(selector)s}[$__interval])
            %(replicaSelectorSnippet)s
          ) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Slowlog Events - Primary',
        yAxisLabel='Events',
        query=|||
          sum(changes(redis_slowlog_last_id{%(selector)s}[$__interval])
            %(primarySelectorSnippet)s
          ) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=10,
      ),
      basic.timeseries(
        title='Slowlog Events - Replicas',
        yAxisLabel='Events',
        query=|||
          sum(changes(redis_slowlog_last_id{%(selector)s}[$__interval])
            %(replicaSelectorSnippet)s
          ) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=10,
      ),
      basic.timeseries(
        title='Operation Rate per Command - Primary',
        yAxisLabel='Operations/sec',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_total{%(selector)s}[$__interval])
            %(primarySelectorSnippet)s
          ) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Operation Rate per Command - Replicas',
        yAxisLabel='Operations/sec',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_total{%(selector)s}[$__interval])
            %(replicaSelectorSnippet)s
          ) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Average Operation Latency - Primary',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_duration_seconds_total{%(selector)s}[$__interval])
            %(primarySelectorSnippet)s
          ) by (cmd)
          /
          sum(rate(redis_commands_total{%(selector)s}[$__interval])) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Average Operation Latency - Replicas',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_duration_seconds_total{%(selector)s}[$__interval])
            %(replicaSelectorSnippet)s
          ) by (cmd)
          /
          sum(rate(redis_commands_total{%(selector)s}[$__interval])) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Total Operation Latency - Primary',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_duration_seconds_total{%(selector)s}[$__interval])
            %(primarySelectorSnippet)s
          ) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Total Operation Latency - Replicas',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_duration_seconds_total{%(selector)s}[$__interval])
            %(replicaSelectorSnippet)s
          ) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),

    ], cols=2, rowHeight=10, startRow=startRow),

  data(serviceType, startRow, hitRatio=false, cluster=false)::
    local formatConfig = {
      selector: selectors.serializeHash({
        environment: '$environment',
        type: serviceType,
        [if cluster then 'shard']: { re: '$shard' },
      }),
    };
    local charts = [
                     basic.saturationTimeseries(
                       title='Memory Saturation',
                       // TODO: After upgrading to Redis 4, we should include the rdb_last_cow_size in this value
                       // so that we include the RDB snapshot utilization in our memory usage
                       // See https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3785#note_234689504
                       description='Redis holds all data in memory. Avoid memory saturation in Redis at all cost ',
                       query=|||
                         max(
                           label_replace(redis_memory_used_rss_bytes{%(selector)s}, "memtype", "rss","","")
                           or
                           label_replace(redis_memory_used_bytes{%(selector)s}, "memtype", "used","","")
                         ) by (type, stage, environment, instance)
                         / on(instance) group_left
                         node_memory_MemTotal_bytes{%(selector)s}
                       ||| % formatConfig,
                       legendFormat='{{ pod }} {{ instance }}',
                       interval='30s',
                       intervalFactor=1,
                     )
                     .addSeriesOverride(seriesOverrides.degradationSlo)
                     .addSeriesOverride(seriesOverrides.outageSlo)
                     .addTarget(
                       promQuery.target(
                         |||
                           max(slo:max:soft:gitlab_component_saturation:ratio{component="redis_memory", environment="$environment"})
                         ||| % formatConfig,
                         interval='5m',
                         legendFormat='Degradation SLO',
                       ),
                     )
                     .addTarget(
                       promQuery.target(
                         |||
                           max(slo:max:hard:gitlab_component_saturation:ratio{component="redis_memory", environment="$environment"})
                         ||| % formatConfig,
                         interval='5m',
                         legendFormat='Outage SLO',
                       ),
                     ),
                     basic.timeseries(
                       title='Memory Used',
                       format='bytes',
                       query=|||
                         max_over_time(redis_memory_used_bytes{%(selector)s}[$__interval])
                       ||| % formatConfig,
                       legendFormat='{{ pod }} {{ instance }}',
                       intervalFactor=2,
                     ),
                     basic.timeseries(
                       title='Memory Used Rate of Change',
                       yAxisLabel='Bytes/sec',
                       format='Bps',
                       query=|||
                         sum(rate(redis_memory_used_bytes{%(selector)s}[$__interval])) by (instance, pod)
                       ||| % formatConfig,
                       legendFormat='{{ pod }} {{ instance }}',
                       intervalFactor=2,
                     ),
                     basic.timeseries(
                       title='Redis RSS Usage',
                       description='Depending on the memory allocator used, Redis may not return memory to the operating system at the same rate that applications release keys. RSS indicates the operating systems perspective of Redis memory usage. So, even if usage is low, if RSS is high, the OOM killer may terminate the Redis process',
                       format='bytes',
                       query=|||
                         max_over_time(redis_memory_used_rss_bytes{%(selector)s}[$__interval])
                       ||| % formatConfig,
                       legendFormat='{{ pod }} {{ instance }}',
                       intervalFactor=2,
                     ),
                     basic.timeseries(
                       title='Memory Fragmentation',
                       description='The fragmentation ratio in Redis should ideally be around 1.0 and generally below 1.5. The higher the value, the more wasted memory.',
                       query=|||
                         redis_memory_used_rss_bytes{%(selector)s} / redis_memory_used_bytes{%(selector)s}
                       ||| % formatConfig,
                       legendFormat='{{ pod }} {{ instance }}',
                       intervalFactor=2,
                     ),
                     basic.timeseries(
                       title='Expired Keys',
                       yAxisLabel='Keys',
                       query=|||
                         sum(rate(redis_expired_keys_total{%(selector)s}[$__interval])) by (instance, pod)
                       ||| % formatConfig,
                       legendFormat='{{ pod }} {{ instance }}',
                       intervalFactor=2,
                     ),
                     basic.timeseries(
                       title='Keys Rate of Change',
                       yAxisLabel='Keys/sec',
                       query=|||
                         sum(rate(redis_db_keys{%(selector)s}[$__interval])) by (instance, pod)
                       ||| % formatConfig,
                       legendFormat='{{ pod }} {{ instance }}',
                       intervalFactor=2,
                     ),
                   ] +
                   if hitRatio then
                     [
                       basic.timeseries(
                         title='Hit Ratio',
                         yAxisLabel='Hits',
                         format='percentunit',
                         query=|||
                           sum(redis:keyspace_hits:irate1m{%(selector)s} and on (instance) redis_instance_info{role="master"})
                           /
                           (
                           sum(redis:keyspace_hits:irate1m{%(selector)s} and on (instance) redis_instance_info{role="master"})
                           +
                           sum(redis:keyspace_misses:irate1m{%(selector)s} and on (instance) redis_instance_info{role="master"})
                           )
                         ||| % formatConfig,
                         legendFormat='{{ pod }} {{ instance }}',
                         intervalFactor=2,
                       ),
                     ]
                   else
                     []
    ;

    layout.grid(charts, cols=2, rowHeight=10, startRow=startRow),

  replication(serviceType, startRow, cluster=false)::
    local formatConfig = {
      selector: selectors.serializeHash({
        environment: '$environment',
        type: serviceType,
        [if cluster then 'shard']: { re: '$shard' },
      }),
    };
    layout.grid([
      basic.timeseries(
        title='Connected Secondaries',
        yAxisLabel='Secondaries',
        query=|||
          sum(avg_over_time(redis_connected_slaves{%(selector)s}[$__interval])) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Replication Offset',
        yAxisLabel='Bytes',
        format='bytes',
        query=|||
          redis_master_repl_offset{%(selector)s}
          - on(instance) group_right
          redis_connected_slave_offset_bytes{%(selector)s}
        ||| % formatConfig,
        legendFormat='secondary {{ slave_ip }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Resync Events',
        yAxisLabel='Events',
        query=|||
          sum(increase(redis_slave_resync_total{%(selector)s}[$__interval])) by (instance, pod)
        ||| % formatConfig,
        legendFormat='{{ pod }} {{ instance }}',
        intervalFactor=2,
      ),
    ], cols=2, rowHeight=10, startRow=startRow),

  cluster(serviceType, startRow)::
    local formatConfig = {
      serviceType: serviceType,
    };

    layout.singleRow([
      basic.statPanel(
        title='Shard Count',
        panelTitle='Number of Shards',
        color='light-green',
        query=|||
          count(count by (shard) (redis_cluster_size{environment="$environment", shard=~"$shard", type="%(serviceType)s"}))
        ||| % formatConfig,
      ),
      basic.statPanel(
        title='Nodes',
        panelTitle='Redis Cluster Node Count',
        color='light-green',
        query=|||
          max(redis_cluster_known_nodes{environment="$environment", type="%(serviceType)s"})
        ||| % formatConfig,
      ),
      basic.statPanel(
        title='OK',
        panelTitle='Redis Cluster Slots OK',
        color='light-green',
        query=|||
          max(redis_cluster_slots_ok{environment="$environment", shard=~"$shard", type="%(serviceType)s"})
        ||| % formatConfig,
      ),
      basic.statPanel(
        title='assigned',
        panelTitle='Redis Cluster Slots Assigned',
        color='light-green',
        query=|||
          max(redis_cluster_slots_assigned{environment="$environment", shard=~"$shard", type="%(serviceType)s"})
        ||| % formatConfig,
      ),
      basic.statPanel(
        title='pfail',
        panelTitle='Redis Cluster Slots Rfailed',
        color='light-orange',
        query=|||
          max(redis_cluster_slots_pfail{environment="$environment", shard=~"$shard", type="%(serviceType)s"})
        ||| % formatConfig,
      ),
      basic.statPanel(
        title='failed',
        panelTitle='Redis Cluster Slots Failed',
        color='light-red',
        query=|||
          max(redis_cluster_slots_fail{environment="$environment", shard=~"$shard", type="%(serviceType)s"})
        ||| % formatConfig,
      ),
    ], rowHeight=4, startRow=startRow)
    +
    layout.grid([
      basic.statPanel(
        panelTitle='Shard Sizes',
        title='Shard ${__series.name} size',
        color='light-green',
        query=|||
          count(rate(redis_cluster_size{environment="$environment", shard=~"$shard", type="%(serviceType)s"}[$__interval])) by (shard)
        ||| % formatConfig,
        legendFormat='{{ shard }}',
      ),
    ], cols=1, rowHeight=4, startRow=startRow + 4),

  redisDashboard(service, cluster=false, hitRatio=false)::
    local dashboard = serviceDashboard.overview(service)
                      .addPanel(
      row.new(title='Clients'),
      gridPos={
        x: 0,
        y: 1000,
        w: 24,
        h: 1,
      }
    )
                      .addPanels(self.clientPanels(serviceType=service, startRow=1001, cluster=cluster))
                      .addPanel(
      row.new(title='Workload'),
      gridPos={
        x: 0,
        y: 2000,
        w: 24,
        h: 1,
      }
    )
                      .addPanels(self.workload(serviceType=service, startRow=2001, cluster=cluster))
                      .addPanel(
      row.new(title='Redis Data'),
      gridPos={
        x: 0,
        y: 3000,
        w: 24,
        h: 1,
      }
    )
                      .addPanels(self.data(serviceType=service, startRow=3001, hitRatio=hitRatio, cluster=cluster))
                      .addPanel(
      row.new(title='Replication'),
      gridPos={
        x: 0,
        y: 4000,
        w: 24,
        h: 1,
      }
    )
                      .addPanels(self.replication(serviceType=service, startRow=4001, cluster=cluster));

    if cluster then
      dashboard
      .addTemplate(templates.shard)
      .addPanel(
        row.new(title='Cluster Data'),
        gridPos={
          x: 0,
          y: 5000,
          w: 24,
          h: 1,
        }
      )
      .addPanels(self.cluster(serviceType=service, startRow=5001))
    else
      dashboard.addPanel(
        row.new(title='Sentinel Processes', collapse=true)
        .addPanels(
          processExporter.namedGroup(
            'sentinel',
            {
              environment: '$environment',
              groupname: { re: 'redis-sentinel.*' },
              type: service,
              stage: '$stage',
            },
            startRow=1
          )
        ),
        gridPos={
          x: 0,
          y: 5000,
          w: 24,
          h: 1,
        },
      ),
}
