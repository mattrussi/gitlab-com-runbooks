local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;

local commonAnnotations = import 'common_annotations.libsonnet';
local templates = import 'templates.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local text = grafana.text;
local rcaLayout = import 'rcas/rca.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';

dashboard.new(
  '2019-12-03',
  schemaVersion=16,
  tags=['rca'],
  timezone='utc',
  graphTooltip='shared_crosshair',
  time_from='2019-12-02T00:00:00.000Z',
  time_to='2019-12-03T00:00:00.000Z',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanels(rcaLayout.rcaLayout([
  {
    description: |||
      # Workhorse 502s and 503s

      The rate at which we're experiencing 502 and 503 errors is elevated.
      This could be due to timeouts.

      But what is causing the timeouts?

      Lower is better.
    |||,
    query: |||
      sum(rate(gitlab_workhorse_http_requests_total{code=~"503|502", environment="gprd", env="gprd"}[$__interval]))
    |||,
  },
  {
    description: |||
      # Web Apdex

      What percentage of web requests complete within the cutoff threshold?

      We can see that latency spikes lead to the 502/503 errors we see in Workhorse, in the top panel

      Higher is better.
    |||,
    panel: keyMetrics.apdexPanel('web', 'main'),
  },
  {
    description: |||
      # Web Errors

      What percentage of web requests fail?

      Lower is better.
    |||,
    panel: keyMetrics.errorRatesPanel('web', 'main', includeLastWeek=false),
  },
  {
    description: |||
      # FindCommits inflight

      The number of inflight FindCommits is correlated to 502s and latencies issues on the frontend.
    |||,
    query: |||
      grpc_server_started_total{job="gitaly", env="gprd", grpc_method="FindCommit"} - sum(grpc_server_handled_total{job="gitaly", env="gprd", grpc_method="FindCommit"}) without (grpc_code)
    |||,
    legendFormat: '{{ fqdn }}',
  },
  {
    description: |||
      # FindCommits Start Rate

      The rate at which FindCommits are being invoked does not change. This implies that the pile-ups that we
      see in FindCommits inflight (above) must be caused by server-side Gitaly slowdowns.
    |||,
    query: |||
      rate(grpc_server_started_total{job="gitaly", env="gprd", grpc_method="FindCommit"}[$__interval])
    |||,
    legendFormat: '{{ fqdn }}',
  },
  {
    description: |||
      # FindCommits Estimated p90 Latency

      Variations in FindCommit latency seem to lead to the slowdowns we see on the web frontend.

      What could be causing these slowdowns on these Gitaly services?
    |||,
    query: |||
      histogram_quantile(0.9, sum(rate(grpc_server_handling_seconds_bucket{job="gitaly", env="gprd", grpc_method="FindCommit"}[5m])) by (fqdn, le))
    |||,
    legendFormat: '{{ fqdn }}',
    intervalFactor: 1,
  },
  {
    description: |||
      Gitaly Disk IO Time
    |||,
    query: |||
      rate(node_disk_io_time_seconds_total{env="gprd", type="gitaly", device="sdb"}[$__interval])
    |||,
    legendFormat: '{{ fqdn }}',
    intervalFactor: 1,
  },
  {
    description: |||
      Gitaly Reads Completed
    |||,
    query: |||
      rate(node_disk_reads_completed_total{env="gprd", type="gitaly", device="sdb"}[$__interval])
    |||,
    legendFormat: '{{ fqdn }}',
    intervalFactor: 1,
  },
  {
    description: |||
      Gitaly Writes Completed
    |||,
    query: |||
      rate(node_disk_writes_completed_total{env="gprd", type="gitaly", device="sdb"}[$__interval])
    |||,
    legendFormat: '{{ fqdn }}',
    intervalFactor: 1,
  },
  {
    description: |||
      ??
    |||,
    query: |||
      rate(gitaly_catfile_cache_total{env="gprd", job="gitaly"}[$__interval])
    |||,
    intervalFactor: 1,
  },
  {
    description: |||
      ??
    |||,
    query: |||
      rate(gitaly_catfile_processes_total{env="gprd", job="gitaly"}[$__interval])
    |||,
    intervalFactor: 1,
  },
  {
    description: |||
      ??
    |||,
    query: |||
      rate(gitaly_commands_running{env="gprd", job="gitaly"}[$__interval])
    |||,
    intervalFactor: 1,
  },
  {
    description: |||
      # Gitaly Repack Rate
    |||,
    query: |||
      sum(increase(gitaly_repack_total[$__interval])) without (bitmap)
    |||,
    intervalFactor: 10,
  },
  {
    description: |||
      # Gitaly Concurrency Rate Limiting Lock
    |||,
    query: |||
      rate(gitaly_rate_limiting_acquiring_seconds_sum{env="gprd"}[1h])
    |||,
    intervalFactor: 10,
  },
]))
