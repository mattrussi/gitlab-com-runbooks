local basic = import 'grafana/basic.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

{
  in_process(selectorHash, legend, useTimeSeriesPlugin=false)::
    if useTimeSeriesPlugin then
      panel.timeSeries(
        title='Gitaly pack-objects concurrency',
        query=|||
          max(gitaly_pack_objects_in_progress{%(selector)s}) by (fqdn)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        interval='$__interval',
        linewidth=1,
      )
    else
      basic.timeseries(
        title='Gitaly pack-objects concurrency',
        query=|||
          max(gitaly_pack_objects_in_progress{%(selector)s}) by (fqdn)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        interval='$__interval',
        linewidth=1,
      ),
  queued_commands(selectorHash, legend, useTimeSeriesPlugin=false)::
    if useTimeSeriesPlugin then
      panel.timeSeries(
        title='Gitaly pack-objects queued commands (gauage)',
        query=|||
          max(gitaly_pack_objects_queued{%(selector)s}) by (fqdn)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        interval='$__interval',
        linewidth=1,
      )
    else
      basic.timeseries(
        title='Gitaly pack-objects queued commands (gauage)',
        query=|||
          max(gitaly_pack_objects_queued{%(selector)s}) by (fqdn)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        interval='$__interval',
        linewidth=1,
      ),
  dropped_commands(selectorHash, legend, useTimeSeriesPlugin=false)::
    if useTimeSeriesPlugin then
      panel.timeSeries(
        title='Gitaly pack-objects dropped commands (RPS)',
        query=|||
          sum(rate(gitaly_pack_objects_dropped_total{%(selector)s}[$__rate_interval])) by (fqdn, reason)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        interval='$__interval',
        linewidth=1,
      )
    else
      basic.timeseries(
        title='Gitaly pack-objects dropped commands (RPS)',
        query=|||
          sum(rate(gitaly_pack_objects_dropped_total{%(selector)s}[$__rate_interval])) by (fqdn, reason)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        interval='$__interval',
        linewidth=1,
      ),
  queueing_time(selectorHash, legend, useTimeSeriesPlugin=false)::
    if useTimeSeriesPlugin then
      panel.timeSeries(
        title='95th queueing time (RPS)',
        query=|||
          histogram_quantile(0.95, sum(rate(gitaly_pack_objects_acquiring_seconds_bucket{%(selector)s}[$__rate_interval])) by (le, fqdn))
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        interval='$__interval',
        linewidth=1,
        format='s',
      )
    else
      basic.timeseries(
        title='95th queueing time (RPS)',
        query=|||
          histogram_quantile(0.95, sum(rate(gitaly_pack_objects_acquiring_seconds_bucket{%(selector)s}[$__rate_interval])) by (le, fqdn))
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        interval='$__interval',
        linewidth=1,
        format='s',
      ),
  cache_lookup(selectorHash, legend, useTimeSeriesPlugin=false)::
    if useTimeSeriesPlugin then
      panel.timeSeries(
        title='Gitaly pack-objects cache',
        query=|||
          sum(rate(gitaly_pack_objects_cache_lookups_total{%(selector)s}[$__rate_interval])) by (result)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        interval='$__interval',
        linewidth=1,
      )
    else
      basic.timeseries(
        title='Gitaly pack-objects cache',
        query=|||
          sum(rate(gitaly_pack_objects_cache_lookups_total{%(selector)s}[$__rate_interval])) by (result)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        interval='$__interval',
        linewidth=1,
        decimals=2,
      ),
  cache_served(selectorHash, legend, useTimeSeriesPlugin=false)::
    if useTimeSeriesPlugin then
      panel.timeSeries(
        title='Gitaly pack-objects cache served bytes',
        query=|||
          sum(rate(gitaly_pack_objects_served_bytes_total{%(selector)s}[$__rate_interval])) by (fqdn)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        format='bytes',
        interval='$__interval',
        linewidth=1,
      )
    else
      basic.timeseries(
        title='Gitaly pack-objects cache served bytes',
        query=|||
          sum(rate(gitaly_pack_objects_served_bytes_total{%(selector)s}[$__rate_interval])) by (fqdn)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        format='bytes',
        interval='$__interval',
        linewidth=1,
        decimals=2,
      ),
  cache_generated(selectorHash, legend, useTimeSeriesPlugin=false)::
    if useTimeSeriesPlugin then
      panel.timeSeries(
        title='Gitaly pack-objects cache generated bytes',
        query=|||
          sum(rate(gitaly_pack_objects_generated_bytes_total{%(selector)s}[$__rate_interval])) by (fqdn)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        format='bytes',
        interval='$__interval',
        linewidth=1,
      )
    else
      basic.timeseries(
        title='Gitaly pack-objects cache generated bytes',
        query=|||
          sum(rate(gitaly_pack_objects_generated_bytes_total{%(selector)s}[$__rate_interval])) by (fqdn)
        ||| % { selector: selectors.serializeHash(selectorHash) },
        legendFormat=legend,
        format='bytes',
        interval='$__interval',
        linewidth=1,
        decimals=2,
      ),
  pack_objects_info()::
    basic.text(
      title='Gitaly Pack-Objects cache info',
      content=|||
        Gitaly is caching short rolling window of <a href="https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/gprd-base-stor-gitaly-common.json?ref_type=heads#L185">5 minutes</a> of Git fetch responses. It is independent of (verbatim from <a href="https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/gitaly/gitaly-repos-cgroup.md">docs</a>):

        1. The transport (HTTP or SSH)
        2. Git protocol version (v0 or v2)
        3. The type of fetch, such as full clones, incremental fetches, shallow clones, or partial clones]

        Here is the link to docs to understand more about pack-object cache:
        https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/gitaly/gitaly-repos-cgroup.md
      |||
    ),
}
