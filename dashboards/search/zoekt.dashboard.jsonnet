local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local row = grafana.row;

local timeseriesGraph(title, query) =
  basic.timeseries(
    title=title,
    stableId='gitlab-zoekt-%s' % std.asciiLower(title),
    decimals='2',
    query=query,
  );

local searchRate() =
  local title = 'Search Rate 5m';
  basic.timeseries(
    title=title,
    stableId='gitlab-zoekt-%s' % std.asciiLower(title),
    legendFormat='{{container}}',
    decimals='2',
    query=|||
      rate(zoekt_search_requests_total{env="$environment"}[5m])
    |||,
    intervalFactor=1,
  );


local errorRate() =
  local title = 'Error Rate 5m';
  basic.timeseries(
    title=title,
    stableId='gitlab-zoekt-%s' % std.asciiLower(title),
    legendFormat='{{container}}',
    decimals='2',
    query=|||
      rate(zoekt_search_failed_total{env="$environment"}[5m])
    |||,
  );

local searchesPercentile(percentile) =
  local title = 'Search Duration %(percentile)sth Percentile' % { percentile: percentile * 100.0 };
  basic.timeseries(
    title=title,
    stableId='gitlab-zoekt-%s' % std.asciiLower(title),
    yAxisLabel='seconds',
    decimals='2',
    legendFormat='{{container}}',
    query=|||
      histogram_quantile(%(percentile)s, sum by (container, le) (rate(zoekt_search_duration_seconds_bucket{env="$environment"}[10m])))
    ||| % { percentile: percentile },
  );


local diskUtilization() =
  local title = 'Persistent Volume Disk Utilization';
  basic.timeseries(
    title=title,
    yAxisLabel='% utilization',
    stableId='gitlab-zoekt-%s' % std.asciiLower(title),
    legendFormat='{{persistentvolumeclaim}}',
    decimals='2',
    query=|||
      sum(kubelet_volume_stats_used_bytes{env="$environment", persistentvolumeclaim=~"zoekt-index-gitlab-gitlab-zoekt.*"}
      / kubelet_volume_stats_capacity_bytes{env="$environment", persistentvolumeclaim=~"zoekt-index-gitlab-gitlab-zoekt.*"}) by (persistentvolumeclaim)

    |||,
  )
  .addTarget(
    promQuery.target('80', legendFormat='80% Threshold')
  )
  .addSeriesOverride({
    alias: '80% Threshold',
    color: 'red',
    dashes: true,
    stack: true,
  })
;


local diskReads() =
  timeseriesGraph(
    title='I/O Reads',
    query=|||
      sum(rate(container_fs_reads_bytes_total{pod=~"gitlab-gitlab-zoekt.*", container=~"zoekt.*", env="$environment"}[5m])) by (container, pod)
    |||,
  );

local diskWrites() =
  timeseriesGraph(
    title='I/O Writes',
    query=|||
      sum(rate(container_fs_writes_bytes_total{pod=~"gitlab-gitlab-zoekt.*", container=~"zoekt.*", env="$environment"}[5m])) by (container, pod)
    |||,
  );

local memoryUsage() =
  local title = 'Memory Map Usage';
  basic.timeseries(
    title=title,
    stableId='gitlab-zoekt-%s' % std.asciiLower(title),
    query=|||
      sum(proc_metrics_memory_map_current_count{pod=~"gitlab-gitlab-zoekt.*", container=~"zoekt.*", env="$environment"}) by (container, pod)
    |||,
  )
  .addTarget(
    promQuery.target(
      |||
        min(proc_metrics_memory_map_max_limit{pod=~"gitlab-gitlab-zoekt.*", container=~"zoekt.*", env="$environment"})
      |||,
      legendFormat='Memory Map Limit'
    )
  )
  .addSeriesOverride({
    alias: 'Memory Map Limit',
    color: 'red',
    dashes: true,
  })
;

local cpuUsage() =
  timeseriesGraph(
    title='CPU Usage',
    query=|||
      sum(rate(container_cpu_usage_seconds_total{pod=~"gitlab-gitlab-zoekt.*", container=~"zoekt.*", env="$environment"}[5m]))by (container, pod)
    |||,
  );

local cpuThrottling() =
  timeseriesGraph(
    title='CPU Throttling',
    query=|||
      sum(rate(container_cpu_cfs_throttled_seconds_total{pod=~"gitlab-gitlab-zoekt.*", container=~"zoekt.*", env="$environment"}[5m]))by (container, pod)
    |||,
  );


basic.dashboard(
  'Zoekt Info',
  tags=['zoekt', 'search'],
)
.addPanels(
  layout.rowGrid(
    'Performance',
    [
      searchesPercentile(0.98),
      searchRate(),
      errorRate(),
    ],
    startRow=10,
  ),
)
.addPanels(
  layout.rowGrid(
    'Disk',
    [
      diskUtilization(),
      diskReads(),
      diskWrites(),

    ],
    startRow=20,
  )
)
.addPanels(
  layout.rowGrid(
    'CPU / Memory',
    [
      memoryUsage(),
      cpuUsage(),
      cpuThrottling(),

    ],
    startRow=30,
  )
)
.addPanels(
  layout.rowGrid(
    'Additional Resources',
    [
      basic.text(
        content=|||

          ### Zoekt Rollout Epic

          See https://gitlab.com/groups/gitlab-org/-/epics/9404

          ### Helpful Links

          - [Memory Usage](https://dashboards.gitlab.net/d/kubernetes-resources-pod/kubernetes-compute-resources-pod?orgId=1&var-datasource=default&var-cluster=gprd-gitlab-gke&var-namespace=gitlab&var-pod=gitlab-gitlab-zoekt-0&from=now-6h&to=now)
          - [Sourcegraph Observability Documentation](https://docs.sourcegraph.com/admin/observability/dashboards)
        |||,
      ),
    ],
    startRow=40
  )
)
