local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local colorScheme = import 'grafana/color_scheme.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local multiburnFactors = import 'mwmbr/multiburn_factors.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local gitalyPackObjectsDashboards = import 'gitlab-dashboards/gitaly/pack_objects.libsonnet';
local gitalyPerRPCDashboards = import 'gitlab-dashboards/gitaly/per_rpc.libsonnet';
local gitalyAdaptiveLimitDashboards = import 'gitlab-dashboards/gitaly/adaptive_limit.libsonnet';

local selector = {
  environment: '$environment',
  type: 'gitaly',
  stage: '$stage',
};

local gitalyServiceInfo = metricsCatalog.getService('gitaly');

local hostChart(
  title,
  query,
  valueColumnTitle,
  thresholds,
  thresholdColors,
  sortDescending
      ) =
  grafana.tablePanel.new(
    title,
    datasource='$PROMETHEUS_DS',
    styles=[
      {
        type: 'hidden',
        pattern: 'Time',
        alias: 'Time',
      },
      {
        unit: 'short',
        type: 'string',
        alias: 'fqdn',
        decimals: 2,
        pattern: 'fqdn',
        mappingType: 2,
        link: true,
        linkUrl: '/d/gitaly-host-detail/gitaly-host-detail?orgId=1&var-environment=$environment&var-stage=$stage&var-fqdn=${__cell}',
        linkTooltip: 'Click to navigate to Gitaly Host Detail Dashboard',
      },
      {
        unit: 'percentunit',
        type: 'number',
        alias: valueColumnTitle,
        decimals: 2,
        colors: thresholdColors,
        colorMode: 'row',
        pattern: 'Value',
        thresholds: thresholds,
        mappingType: 1,
      },
    ],
  )
  .addTarget(
    promQuery.target(
      query,
      format='table',
      instant=true
    )
  ) + {
    sort: {
      col: null,
      desc: sortDescending,
    },
  };

serviceDashboard.overview('gitaly')
.addPanel(
  row.new(title='Node Investigation'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    hostChart(
      title='Worst Performing Gitaly Nodes by Apdex Score SLI',
      query=|||
        bottomk(8,
          avg by (fqdn) (
            gitlab_service_node_apdex:ratio_5m{environment="$environment", type="gitaly", stage="$stage"}
          )
        )
      |||,
      valueColumnTitle='Apdex Score',
      thresholds=[
        multiburnFactors.apdexRatioThreshold(gitalyServiceInfo.monitoringThresholds.apdexScore, windowDuration='1h'),
        multiburnFactors.apdexRatioThreshold(gitalyServiceInfo.monitoringThresholds.apdexScore, windowDuration='6h'),
      ],
      thresholdColors=[
        colorScheme.criticalColor,
        colorScheme.errorColor,
        'black',
      ],
      sortDescending=true
    ),
    hostChart(
      title='Worst Performing Gitaly Nodes by Error Rate SLI',
      query=|||
        topk(8,
          avg by (fqdn) (
            gitlab_service_node_errors:ratio_5m{environment="$environment", type="gitaly", stage="$stage"}
          )
        )
      |||,
      valueColumnTitle='Error Rate',
      thresholds=[
        multiburnFactors.errorRatioThreshold(gitalyServiceInfo.monitoringThresholds.errorRatio, windowDuration='6h'),
        multiburnFactors.errorRatioThreshold(gitalyServiceInfo.monitoringThresholds.errorRatio, windowDuration='1h'),
      ],
      thresholdColors=[
        'black',
        colorScheme.errorColor,
        colorScheme.criticalColor,
      ],
      sortDescending=false
    ),

  ], startRow=2001, cols=2)
)
.addPanel(
  row.new(title='Blackbox exporter metrics'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Gitaly first packet to total request time ratio (GET)',
      query=|||
        gitaly_blackbox_git_http_get_first_packet_seconds{%(selector)s}
        /
        gitaly_blackbox_git_http_get_total_time_seconds{%(selector)s}
      ||| % { selector: selectors.serializeHash(selector) },
      legendFormat='{{ probe }}',
      interval='1m',
      linewidth=1,
    ),
    basic.timeseries(
      title='Gitaly first packet to total request time ratio',
      query=|||
        (
          gitaly_blackbox_git_http_post_first_pack_packet_seconds{%(selector)s}
          +
          gitaly_blackbox_git_http_get_first_packet_seconds{%(selector)s}
        )
        /
        (
          gitaly_blackbox_git_http_post_total_time_seconds{%(selector)s}
          +
          gitaly_blackbox_git_http_get_total_time_seconds{%(selector)s}
        )
      ||| % { selector: selectors.serializeHash(selector) },
      legendFormat='{{ probe }}',
      interval='1m',
      linewidth=1,
    ),
    basic.timeseries(
      title='Gitaly wanted refs to total request time ratio',
      query=|||
        gitaly_blackbox_git_http_wanted_refs{%(selector)s}
        /
        gitaly_blackbox_git_http_get_total_time_seconds{%(selector)s}
      ||| % { selector: selectors.serializeHash(selector) },
      legendFormat='{{ probe }}',
      interval='1m',
      linewidth=1,
    ),
    basic.timeseries(
      title='Gitaly request total time to request total size ratio (POST)',
      query=|||
        gitaly_blackbox_git_http_post_total_time_seconds{%(selector)s}
        /
        gitaly_blackbox_git_http_post_pack_bytes{%(selector)s}
      ||| % { selector: selectors.serializeHash(selector) },
      legendFormat='{{ probe }}',
      interval='1m',
      linewidth=1,
    ),
  ], startRow=3001)
)
.addPanel(
  row.new(title='Pack objects metrics'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    gitalyAdaptiveLimitDashboards.pack_objects_current_limit(selector, '{{ fqdn }}'),
    gitalyPackObjectsDashboards.in_process(selector, '{{ fqdn }}'),
    gitalyPackObjectsDashboards.queued_commands(selector, '{{ fqdn }}'),
    gitalyPackObjectsDashboards.queueing_time(selector, '{{ fqdn }}'),
    gitalyPackObjectsDashboards.dropped_commands(selector, '{{ fqdn }}'),
    gitalyPackObjectsDashboards.cache_lookup(selector, '{{ result }}'),
  ], startRow=4001)
)
.addPanel(
  row.new(title='Per-RPC metrics'),
  gridPos={
    x: 0,
    y: 5000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    gitalyPerRPCDashboards.in_progress_requests_by_node(selector),
    gitalyPerRPCDashboards.queued_requests_by_node(selector),
    gitalyPerRPCDashboards.queueing_time_by_node(selector),
    gitalyPerRPCDashboards.dropped_requests_by_node(selector),
  ], startRow=5001)
)
.addPanel(
  row.new(title='Adaptive limit metrics'),
  gridPos={
    x: 0,
    y: 6000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    gitalyAdaptiveLimitDashboards.backoff_events(selector, '{{ fqdn }}'),
    gitalyAdaptiveLimitDashboards.watcher_errors(selector, '{{ fqdn }}'),
  ], startRow=6001)
)
.overviewTrailer()
