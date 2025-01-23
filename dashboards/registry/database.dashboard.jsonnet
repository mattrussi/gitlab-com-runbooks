local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local crCommon = import 'gitlab-dashboards/container_registry_graphs.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local graphPanel = grafana.graphPanel;
local promQuery = import 'grafana/prom_query.libsonnet';
local statPanel = grafana.statPanel;
local colorScheme = import 'grafana/color_scheme.libsonnet';

local bloatThresholds = [
  { color: colorScheme.normalRangeColor, value: 0.25 },
  { color: colorScheme.warningColor, value: 0.30 },
  { color: colorScheme.errorColor, value: 0.40 },
];

basic.dashboard(
  'Database Detail',
  tags=['container registry', 'docker', 'registry'],
)
.addTemplate(templates.stage)
.addTemplate(templates.namespaceGitlab)
.addTemplate(
  template.custom(
    'Deployment',
    'gitlab-registry,',
    'gitlab-registry',
    hide='variable',
  )
)
.addTemplate(template.new(
  'cluster',
  '$PROMETHEUS_DS',
  'label_values(go_sql_dbstats_connections_in_use{app="registry", environment="$environment"}, cluster)',
  current=null,
  refresh='load',
  sort=true,
  multi=true,
  includeAll=true,
  allValues='.*',
))
.addTemplate(template.new(
  'shard',
  '$PROMETHEUS_DS',
  'label_values(gitlab_database_bloat_btree_bloat_size{type="patroni-registry", environment="$environment"}, shard)',
  current='default',
  refresh='load',
  sort=true,
  multi=true,
  includeAll=true,
  allValues='.*',
))
.addPanel(
  row.new(title='Overview'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    statPanel.new(
      title='RPS',
      description='The per-second rate of all database queries performed on the application side.',
      reducerFunction='last',
      decimals=0,
    )
    .addTarget(
      promQuery.target(
        |||
          sum (
            rate(registry_database_queries_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||
      )
    ),
    statPanel.new(
      title='Latency',
      description='The p90 latency of all database query performed on the application side.',
      decimals=2,
      unit='s',
    )
    .addTarget(
      promQuery.target(
        |||
          histogram_quantile(
            0.900000,
            sum by (le) (
              rate(registry_database_query_duration_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
          )
        |||
      )
    ),
    statPanel.new(
      title='Open Connections',
      description='The total number of established connections both in use and idle.',
      reducerFunction='last',
      decimals=0,
    )
    .addTarget(
      promQuery.target(
        |||
          sum(
            max_over_time(
              go_sql_dbstats_connections_open{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]
            )
          )
        |||
      )
    ),
    statPanel.new(
      title='Connection Pool Saturation',
      reducerFunction='last',
      decimals=0,
      unit='percentunit',
    )
    .addTarget(
      promQuery.target(
        |||
          sum (go_sql_dbstats_connections_open{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"})
          /
          sum (go_sql_dbstats_connections_max_open{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"})
        |||
      )
    )
    .addThresholds(
      [
        { color: colorScheme.normalRangeColor, value: 0.20 },
        { color: colorScheme.warningColor, value: 0.40 },
        { color: colorScheme.errorColor, value: 0.60 },
      ]
    ),
    statPanel.new(
      title='Replica Pool Size',
      description='The current number of replicas in the load balancer pool.',
      reducerFunction='last',
      decimals=0,
    )
    .addTarget(
      promQuery.target(
        |||
          avg(
            max_over_time(
              registry_database_lb_pool_size{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]
            )
          )
        |||
      )
    ),
    statPanel.new(
      title='Table Bloat',
      description='The aggregate table bloat saturation.',
      reducerFunction='last',
      decimals=0,
      unit='percentunit'
    )
    .addTarget(
      promQuery.target(
        |||
          max_over_time(
            gitlab_component_saturation:ratio{type="patroni-registry", environment="$environment", component="pg_table_bloat", shard=~"$shard"}[$__interval]
          )
        |||,
      )
    )
    .addThresholds(bloatThresholds),
    statPanel.new(
      title='B-tree Bloat',
      description='The aggregate B-tree bloat saturation.',
      reducerFunction='last',
      decimals=0,
      unit='percentunit'
    )
    .addTarget(
      promQuery.target(
        |||
          max_over_time(
            gitlab_component_saturation:ratio{type="patroni-registry", environment="$environment", component="pg_btree_bloat", shard=~"$shard"}[$__interval]
          )
        |||,
      )
    )
    .addThresholds(bloatThresholds),
    statPanel.new(
      title='Database Size',
      description='Estimated database size.',
      reducerFunction='lastNotNull',
      decimals=0,
      graphMode='none',
      unit='bytes',
    )
    .addTarget(
      promQuery.target(
        |||
          sum (
            gitlab_database_bloat_table_real_size{type="patroni-registry", environment="$environment", shard=~"$shard"}
          )
          +
          sum (
            gitlab_database_bloat_btree_real_size{type="patroni-registry", environment="$environment", shard=~"$shard"}
          )
        |||
      )
    ),
    statPanel.new(
      title='Batched Migration Worker Runs',
      description='The cumulative count of batched migration worker runs.',
      reducerFunction='last',
      decimals=0,
    )
    .addTarget(
      promQuery.target(
        |||
          sum (
            increase(registry_bbm_runs_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||
      )
    ),
  ], cols=8, rowHeight=4, startRow=1)
)


.addPanel(
  row.new(title='Queries'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='RPS (Aggregate)',
      description='The per-second rate of all database queries performed on the application side.',
      query=|||
        sum (
          rate(registry_database_queries_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
        )
      |||,
      legend_show=false,
      format='ops'
    ),
    graphPanel.new(
      'RPS (Per Query)',
      description='The per-second rate of each database query performed on the application side.',
      format='ops',
      linewidth=1,
      fill=0,
      legend_alignAsTable=true,
      legend_values=true,
      legend_min=true,
      legend_max=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
    )
    .addTarget(
      promQuery.target(
        |||
          sum by (name) (
            rate(registry_database_queries_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ name }}',
      )
    ),
    basic.timeseries(
      title='Latency (Aggregate)',
      description='The p90 latency of all database query performed on the application side.',
      query=|||
        histogram_quantile(
          0.900000,
          sum by (le) (
            rate(registry_database_query_duration_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        )
      |||,
      legend_show=false,
      format='s'
    ),
    graphPanel.new(
      'Latency (Per Query)',
      description='The p90 latency of each database query performed on the application side.',
      format='s',
      linewidth=1,
      fill=0,
      nullPointMode='connected',
      legend_alignAsTable=true,
      legend_values=true,
      legend_min=true,
      legend_max=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
    )
    .addTarget(
      promQuery.target(
        |||
          histogram_quantile(
            0.900000,
            sum by (le, name) (
              rate(registry_database_query_duration_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
          )
        |||,
        legendFormat='{{ name }}',
      )
    ),
  ], cols=4, rowHeight=13, startRow=1001),
)

.addPanel(
  row.new(title='Connection Pool (Aggregate)'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Open',
      description='The total number of established connections both in use and idle.',
      yAxisLabel='Connections',
      query='sum(max_over_time(go_sql_dbstats_connections_open{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))',
      intervalFactor=5,
      legend_show=false
    ),
    basic.timeseries(
      title='In Use',
      description='The total number of connections currently in use.',
      yAxisLabel='Connections',
      query='sum(max_over_time(go_sql_dbstats_connections_in_use{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))',
      intervalFactor=5,
      legend_show=false
    ),
    basic.timeseries(
      title='Idle',
      description='The total aggregated number of idle connections.',
      yAxisLabel='Connections',
      query='sum(max_over_time(go_sql_dbstats_connections_idle{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))',
      intervalFactor=5,
      legend_show=false
    ),
    basic.saturationTimeseries(
      title='Saturation',
      description='Saturation. Lower is better.',
      yAxisLabel='Utilization',
      query=|||
        sum (go_sql_dbstats_connections_open{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"})
        /
        sum (go_sql_dbstats_connections_max_open{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"})
      |||,
      interval='30s',
      intervalFactor=3,
      legend_show=false
    ),
    basic.latencyTimeseries(
      title='Wait Time',
      description='The total aggregated time blocked waiting for a new connection. Lower is better.',
      query='sum(rate(go_sql_dbstats_connections_wait_seconds_total{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))',
      format='s',
      yAxisLabel='Latency',
      interval='1m',
      intervalFactor=1,
      legend_show=false
    ),
    basic.timeseries(
      title='Waits',
      description='The total number of connections waited for.',
      yAxisLabel='Connections',
      query='sum(rate(go_sql_dbstats_connections_waits_total{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))',
      intervalFactor=2,
      legend_show=false
    ),
    basic.timeseries(
      title='Closed (Max Idle Count)',
      description='The total number of connections closed due to the maximum idle count limit.',
      yAxisLabel='Connections',
      query='sum(rate(go_sql_dbstats_connections_max_idle_closed_count_total{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))',
      intervalFactor=2,
      legend_show=false
    ),
    basic.timeseries(
      title='Closed (Max Idle Time)',
      description='The total number of connections closed due to the maximum idle time limit.',
      yAxisLabel='Connections',
      query='sum(rate(go_sql_dbstats_connections_max_idle_time_closed_count_total{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))',
      intervalFactor=2,
      legend_show=false
    ),
    basic.timeseries(
      title='Closed (Max Lifetime)',
      description='The total number of connections closed due to the maximum lifetime limit.',
      yAxisLabel='Connections',
      query='sum(rate(go_sql_dbstats_connections_max_lifetime_closed_count_total{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))',
      intervalFactor=2,
      legend_show=false
    ),
  ], cols=3, rowHeight=10, startRow=2001),
)

.addPanel(
  row.new(title='Connection Pool (Per Pod)', collapse=true)
  .addPanels(
    layout.grid([
      basic.timeseries(
        title='Open',
        description='The number of established connections both in use and idle per pod.',
        query='sum(go_sql_dbstats_connections_open{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}) by (pod)',
        legendFormat='{{ pod }}',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='Connections',
        linewidth=1
      ),
      basic.timeseries(
        title='In Use',
        description='The number of connections currently in use per pod.',
        query='sum(go_sql_dbstats_connections_in_use{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}) by (pod)',
        legendFormat='{{ pod }}',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='Connections',
        linewidth=1
      ),
      basic.timeseries(
        title='Idle',
        description='The number of idle connections per pod.',
        query='sum(go_sql_dbstats_connections_idle{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}) by (pod)',
        legendFormat='{{ pod }}',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='Connections',
        linewidth=1
      ),
      basic.saturationTimeseries(
        title='Saturation',
        description='Saturation per pod. Lower is better.',
        yAxisLabel='Utilization',
        query=|||
          sum by (pod) (go_sql_dbstats_connections_open{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"})
          /
          sum by (pod) (go_sql_dbstats_connections_max_open{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"})
        |||,
        legendFormat='{{ pod }}',
        interval='30s',
        intervalFactor=3,
      ),
      basic.latencyTimeseries(
        title='Wait Time',
        description='The aggregated time blocked waiting for a new connection per pod. Lower is better.',
        query='sum(rate(go_sql_dbstats_connections_wait_seconds_total{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])) by (pod)',
        legendFormat='{{ pod }}',
        format='s',
        yAxisLabel='Latency',
        interval='1m',
        intervalFactor=1,
      ),
      basic.timeseries(
        title='Waits',
        description='The number of connections waited for per pod.',
        query='sum(max_over_time(go_sql_dbstats_connections_waits_total{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])) by (pod)',
        legendFormat='{{ pod }}',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='Connections',
      ),
    ], cols=3, rowHeight=10, startRow=3001),
  ),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  },
)

.addPanel(
  row.new(title='Load Balancing', collapse=true)
  .addPanels(
    layout.grid([
      basic.timeseries(
        title='Replica Pool Size',
        description='The number of replicas in the load balancer pool.',
        yAxisLabel='Replicas',
        query='avg(\n          max_over_time(registry_database_lb_pool_size{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])\n        )',
        legend_show=false
      ),
      basic.timeseries(
        title='Replica Pool Events (Cumulative)',
        description='The cumulative count of replicas added and removed from the pool.',
        query=|||
          sum by (event)(
            increase(registry_database_lb_pool_events_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ event }}',
        format='short'
      ),
      basic.timeseries(
        title='DNS Lookups Rate (Aggregate)',
        description='Rate of DNS lookups over time.',
        query=|||
          sum(
            rate(registry_database_lb_lookup_seconds_count{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legend_show=false,
        format='short'
      ),
      basic.timeseries(
        title='DNS Lookups Rate (Per Type)',
        description='Rate of DNS lookups over time, broken down by type (i.e., srv, host).',
        query=|||
          sum by (lookup_type)(
            rate(registry_database_lb_lookup_seconds_count{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ lookup_type }}',
        format='short'
      ),
      basic.timeseries(
        title='DNS Lookups Latency (Aggregate)',
        description='The p90 latency of all DNS lookups.',
        query=|||
          histogram_quantile(
            0.900000,
            sum by (le) (
              rate(registry_database_lb_lookup_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
          )
        |||,
        legend_show=false,
        format='s'
      ),
      graphPanel.new(
        'DNS Lookups Latency (Per Type)',
        description='The p90 latency of each DNS Lookup type.',
        format='s',
        linewidth=1,
        fill=0,
        nullPointMode='connected',
        legend_alignAsTable=true,
        legend_values=true,
        legend_min=true,
        legend_max=true,
        legend_current=true,
        legend_sort='current',
        legend_sortDesc=true,
      )
      .addTarget(
        promQuery.target(
          |||
            histogram_quantile(
              0.900000,
              sum by (le, lookup_type) (
                rate(registry_database_lb_lookup_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
              )
            )
          |||,
          legendFormat='{{ lookup_type }}',
        )
      ),
      basic.timeseries(
        title='DNS Lookup Error Rate (Aggregate)',
        description='Percentage of failed DNS lookups across all instances.',
        query=|||
          (
            sum(rate(registry_database_lb_lookup_seconds_count{error="true", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))
            /
            sum(rate(registry_database_lb_lookup_seconds_count{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))
          ) * 100
        |||,
        format='percent',
        legend_show=false
      ),
      basic.timeseries(
        title='DNS Lookup Error Rate (Per Type)',
        description='Percentage of failed DNS lookups, split by type (e.g., srv, host).',
        query=|||
          (
            sum by (lookup_type) (
              rate(registry_database_lb_lookup_seconds_count{error="true", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
            /
            sum by (lookup_type) (
              rate(registry_database_lb_lookup_seconds_count{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
          ) * 100
        |||,
        legendFormat='{{ lookup_type }}',
        format='percent'
      ),
      basic.timeseries(
        title='Target Elections (Per Type)',
        description='The rate of primary and replica target elections over time.',
        query=|||
          sum by (target_type) (
            rate(registry_database_lb_targets_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ target_type }}',
        format='short'
      ),
      basic.timeseries(
        title='Target Elections (Per Reason)',
        description='The rate of target elections split by reason for selection or fallback.',
        query=|||
          sum by (reason) (
            rate(registry_database_lb_targets_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ reason }}',
        format='short'
      ),
      basic.timeseries(
        title='Fallback Rate (Aggregate)',
        description='The rate of target elections that resulted in a fallback.',
        query=|||
          sum(
            rate(registry_database_lb_targets_total{fallback="true", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legend_show=false,
        format='short'
      ),
      basic.timeseries(
        title='Fallback Rate (Per Type)',
        description='The rate of fallback elections, split by primary and replica targets.',
        query=|||
          sum by (target_type) (
            rate(registry_database_lb_targets_total{fallback="true", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ target_type }}',
        format='short'
      ),
      basic.timeseries(
        title='Rate of LSN Cache Operations (Aggregate)',
        description='The rate of all LSN cache operations (set and get) combined over time.',
        query=|||
          sum(
            rate(registry_database_lb_lsn_cache_operation_duration_seconds_count{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legend_show=false,
        format='ops',
      ),
      basic.timeseries(
        title='Rate of LSN Cache Operations (Per Operation)',
        description='The rate of LSN cache set and get operations over time, shown separately.',
        query=|||
          sum by (operation) (
            rate(registry_database_lb_lsn_cache_operation_duration_seconds_count{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ operation }}',
        format='ops',
      ),
      basic.timeseries(
        title='LSN Cache Latency (Aggregate)',
        description='The 90th percentile duration for all LSN cache operations (set and get).',
        query=|||
          histogram_quantile(
            0.90,
            sum by (le) (
              rate(registry_database_lb_lsn_cache_operation_duration_seconds_bucket{error="false", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
          )
        |||,
        legend_show=false,
        format='s'
      ),
      basic.timeseries(
        title='LSN Cache Latency (Per Operation)',
        description='The 90th percentile duration for LSN cache set and get operations.',
        query=|||
          histogram_quantile(
            0.90,
            sum by (le, operation) (
              rate(registry_database_lb_lsn_cache_operation_duration_seconds_bucket{error="false", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
          )
        |||,
        legendFormat='{{ operation }}',
        format='s'
      ),
      basic.timeseries(
        title='LSN Cache Error Rate',
        description='The error rate for LSN cache set and get operations.',
        query=|||
          sum by (operation) (
            rate(registry_database_lb_lsn_cache_operation_duration_seconds_count{error="true", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ operation }}',
        format='short'
      ),
      basic.timeseries(
        title='LSN Cache Hit Ratio',
        description='The ratio of LSN cache hits to total requests over time.',
        query=|||
          (sum(rate(registry_database_lb_lsn_cache_hits_total{result="hit", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))
          /
          sum(rate(registry_database_lb_lsn_cache_hits_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval]))) * 100
        |||,
        legend_show=false,
        format='percent',
      ),
      basic.timeseries(
        title='LSN Cache Hit/Miss Rate',
        description='The rate of LSN cache hits and misses over time.',
        query=|||
          sum by (result) (
            rate(registry_database_lb_lsn_cache_hits_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ result }}',
        format='ops',
      ),
    ], cols=4, rowHeight=13, startRow=4001),
  ),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  },
)

.addPanel(
  row.new(title='Table Bloat', collapse=true)
  .addPanels(
    layout.grid([
      basic.saturationTimeseries(
        title='Saturation (Aggregate)',
        description='The aggregate table bloat saturation.',
        query=|||
          max_over_time(
            gitlab_component_saturation:ratio{type="patroni-registry", environment="$environment", component="pg_table_bloat"}[$__interval]
          )
        |||,
        legend_show=false
      ),
      graphPanel.new(
        'Saturation (Per Table)',
        description='The table bloat saturation. Limited to the top 20 entries.',
        format='percent',
        linewidth=1,
        nullPointMode='connected',
        fill=0,
        legend_alignAsTable=true,
        legend_values=true,
        legend_min=true,
        legend_max=true,
        legend_current=true,
        legend_sort='current',
        legend_sortDesc=true,
      )
      .addTarget(
        promQuery.target(
          |||
            topk (
              20,
              max by (query_name) (gitlab_database_bloat_table_bloat_ratio{type="patroni-registry", environment="$environment", shard=~"$shard", query_name!~"pg_.*"})
            )
          |||,
          legendFormat='{{ query_name }}',
        )
      ),
      graphPanel.new(
        'Bloat Size',
        description='The table bloat size. Limited to the top 20 entries.',
        format='bytes',
        linewidth=1,
        nullPointMode='connected',
        fill=0,
        legend_alignAsTable=true,
        legend_values=true,
        legend_min=true,
        legend_max=true,
        legend_current=true,
        legend_sort='current',
        legend_sortDesc=true,
      )
      .addTarget(
        promQuery.target(
          |||
            topk (
              20,
              max by (query_name) (gitlab_database_bloat_table_bloat_size{type="patroni-registry", environment="$environment", shard=~"$shard", query_name!~"pg_.*"})
            )
          |||,
          legendFormat='{{ query_name }}',
        )
      ),
      graphPanel.new(
        'Real Size',
        description='The table real size. Limited to the top 20 entries.',
        format='bytes',
        linewidth=1,
        nullPointMode='connected',
        fill=0,
        legend_alignAsTable=true,
        legend_values=true,
        legend_min=true,
        legend_max=true,
        legend_current=true,
        legend_sort='current',
        legend_sortDesc=true,
      )
      .addTarget(
        promQuery.target(
          |||
            topk (
              20,
              max by (query_name) (gitlab_database_bloat_table_real_size{type="patroni-registry", environment="$environment", shard=~"$shard", query_name!~"pg_.*"})
            )
          |||,
          legendFormat='{{ query_name }}',
        )
      ),
    ], cols=4, rowHeight=13, startRow=4001),
  ),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  },
)

.addPanel(
  row.new(title='B-tree Bloat', collapse=true)
  .addPanels(
    layout.grid([
      basic.saturationTimeseries(
        title='Saturation (Aggregate)',
        description='The aggregate B-tree bloat saturation.',
        query=|||
          max_over_time(
            gitlab_component_saturation:ratio{type="patroni-registry", environment="$environment", component="pg_btree_bloat"}[$__interval]
          )
        |||,
        legend_show=false
      ),
      graphPanel.new(
        'Saturation (Per Index)',
        description='The B-tree bloat saturation per index. Limited to the top 20 entries.',
        format='percent',
        linewidth=1,
        nullPointMode='connected',
        fill=0,
        legend_alignAsTable=true,
        legend_values=true,
        legend_min=true,
        legend_max=true,
        legend_current=true,
        legend_sort='current',
        legend_sortDesc=true,
      )
      .addTarget(
        promQuery.target(
          |||
            topk (
              20,
              max by (query_name) (gitlab_database_bloat_btree_bloat_ratio{type="patroni-registry", environment="$environment", shard=~"$shard", query_name!~"pg_.*"})
            )
          |||,
          legendFormat='{{ query_name }}',
        )
      ),
      graphPanel.new(
        'Bloat Size',
        description='The B-tree bloat size per index. Limited to the top 20 entries.',
        format='bytes',
        linewidth=1,
        nullPointMode='connected',
        fill=0,
        legend_alignAsTable=true,
        legend_values=true,
        legend_min=true,
        legend_max=true,
        legend_current=true,
        legend_sort='current',
        legend_sortDesc=true,
      )
      .addTarget(
        promQuery.target(
          |||
            topk (
              20,
              max by (query_name) (gitlab_database_bloat_btree_bloat_size{type="patroni-registry", environment="$environment", shard=~"$shard", query_name!~"pg_.*"})
            )
          |||,
          legendFormat='{{ query_name }}',
        )
      ),
      graphPanel.new(
        'Real Size',
        description='The B-tree real size per index. Limited to the top 20 entries.',
        format='bytes',
        linewidth=1,
        nullPointMode='connected',
        fill=0,
        legend_alignAsTable=true,
        legend_values=true,
        legend_min=true,
        legend_max=true,
        legend_current=true,
        legend_sort='current',
        legend_sortDesc=true,
      )
      .addTarget(
        promQuery.target(
          |||
            topk (
              20,
              max by (query_name) (gitlab_database_bloat_btree_real_size{type="patroni-registry", environment="$environment", shard=~"$shard", query_name!~"pg_.*"})
            )
          |||,
          legendFormat='{{ query_name }}',
        )
      ),
    ], cols=4, rowHeight=13, startRow=5001),
  ),
  gridPos={
    x: 0,
    y: 5000,
    w: 24,
    h: 1,
  },
)

.addPanel(
  row.new(title='CloudSQL (pre only)', collapse=true)
  .addPanels(
    layout.grid([
      basic.timeseries(
        title='CPU Utilization',
        description=|||
          CPU utilization.

          See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
          more details.
        |||,
        query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_cpu_utilization{database_id=~".+:registry-db.+", environment="$environment"}',
        legendFormat='{{ database_id }}',
        format='percent'
      ),
      basic.timeseries(
        title='Memory Utilization',
        description=|||
          Memory utilization.

          See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
          more details.
        |||,
        query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_memory_utilization{database_id=~".+:registry-db.+", environment="$environment"}',
        legendFormat='{{ database_id }}',
        format='percent'
      ),
      basic.timeseries(
        title='Disk Utilization',
        description=|||
          Data utilization in bytes.

          See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
          more details.
        |||,
        query='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_disk_bytes_used{database_id=~".+:registry-db.+", environment="$environment"}',
        legendFormat='{{ database_id }}',
        format='bytes'
      ),
      basic.timeseries(
        title='Transactions',
        description=|||
          Delta count of number of transactions. Sampled every 60 seconds.

          See https://cloud.google.com/monitoring/api/metrics_gcp#gcp-cloudsql for
          more details.
        |||,
        query=|||
          sum by (database_id) (
            avg_over_time(stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_transaction_count{database_id=~".+:registry-db.+", environment="$environment"}[$__interval])
          )
        |||,
        legendFormat='{{ database_id }}',
      ),
    ], cols=3, rowHeight=10, startRow=6001)
  ),
  gridPos={
    x: 0,
    y: 6000,
    w: 24,
    h: 1,
  },
)

.addPanel(
  row.new(title='Batched Background Migrations', collapse=true)
  .addPanels(
    layout.grid([
      basic.timeseries(
        title='Worker Runs',
        description='The per-second rate of all batched migration worker runs.',
        query=|||
          sum (
            rate(registry_bbm_runs_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__rate_interval])
          )
        |||,
        legend_show=false,
      ),
      basic.timeseries(
        title='Worker Run Latency (Aggregate)',
        description='The p90 latency of all batched migration worker runs.',
        query=|||
          histogram_quantile(
            0.900000,
            sum by (le) (
              rate(registry_bbm_query_duration_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
          )
        |||,
        legend_show=false,
        format='s'
      ),
      basic.timeseries(
        title='Records Migrated (Cumulative)',
        description='The cumulative count of batched migration records migrated.',
        query=|||
          sum by (migration_id)(
            increase(registry_bbm_migrated_tuples_total{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ migration_id }}',
        format='short'
      ),
      basic.timeseries(
        title='Query Rate (Aggregate)',
        description='Rate of batched migration queries over time.',
        query=|||
          sum(
            rate(registry_bbm_query_duration_seconds_count{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legend_show=false,
        format='short'
      ),
      basic.timeseries(
        title='Query Rate (Per Type)',
        description='Rate of batched migration queries over time, broken down by migration ID.',
        query=|||
          sum by (migration_id)(
            rate(registry_bbm_query_duration_seconds_count{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ migration_id }}',
        format='short'
      ),
      basic.timeseries(
        title='Query Latency (Aggregate)',
        description='The p90 latency of all batched migration queries.',
        query=|||
          histogram_quantile(
            0.900000,
            sum by (le) (
              rate(registry_bbm_query_duration_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
          )
        |||,
        legend_show=false,
        format='s'
      ),
      graphPanel.new(
        'Batched Migration Query Latency (Per Migration ID)',
        description='The p90 latency of each batched migration query.',
        format='s',
        linewidth=1,
        fill=0,
        nullPointMode='connected',
        legend_alignAsTable=true,
        legend_values=true,
        legend_min=true,
        legend_max=true,
        legend_current=true,
        legend_sort='current',
        legend_sortDesc=true,
      )
      .addTarget(
        promQuery.target(
          |||
            histogram_quantile(
              0.900000,
              sum by (le, migration_id) (
                rate(registry_bbm_query_duration_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
              )
            )
          |||,
          legendFormat='{{ migration_id }}',
        )
      ),
      basic.timeseries(
        title='Job Latency (Aggregate)',
        description='The 90th percentile duration for all migration jobs.',
        query=|||
          histogram_quantile(
            0.90,
            sum by (le) (
              rate(registry_bbm_job_duration_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
          )
        |||,
        legend_show=false,
        format='s'
      ),
      basic.timeseries(
        title='Job Latency (Per Migration ID)',
        description='The 90th percentile duration for migration jobs per migration ID.',
        query=|||
          histogram_quantile(
            0.90,
            sum by (le, migration_id) (
              rate(registry_bbm_job_duration_seconds_bucket{environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
            )
          )
        |||,
        legendFormat='{{ migration_id }}',
        format='s'
      ),
      basic.timeseries(
        title='Job Size (Per Migration ID)',
        description='The job size of a batched migration.',
        query=|||
          avg by (migration_id) (
            max_over_time(registry_bbm_job_batch_size{app="registry", environment="$environment", cluster=~"$cluster", stage="$stage"}[$__interval])
          )
        |||,
        legendFormat='{{ migration_id }}',
      ),
    ], cols=4, rowHeight=13, startRow=7001),
  ),
  gridPos={
    x: 0,
    y: 7000,
    w: 24,
    h: 1,
  },
)
