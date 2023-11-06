local basic = import 'grafana/basic.libsonnet';
local quantilePanel = import 'grafana/quantile_panel.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

{
  CPUUsagePerCGroup(selector)::
    basic.timeseries(
      title='cgroup: CPU per cgroup',
      description='Rate of CPU usage on every cgroup available on the Gitaly node.',
      query=|||
        topk(20, sum by (id) (rate(container_cpu_usage_seconds_total{%(selector)s}[$__interval])))
      ||| % { selector: selector },
      format='percentunit',
      interval='1m',
      linewidth=1,
      legend_show=false,
      legendFormat='{{ id }}',
    ),

  CPUQuantile(selector)::
    quantilePanel.timeseries(
      title='cgroup: CPU',
      description='P99/PX CPU usage of all cgroups available on the Gitaly node.',
      query=|||
        rate(
          container_cpu_usage_seconds_total{%(selector)s}[$__interval]
        )
      ||| % { selector: selector },
      format='percentunit',
      interval='1m',
      linewidth=1,
      legendFormat='cgroup: CPU',
    ),

  CPUThrottling(selector)::
    basic.timeseries(
      title='cgroup: CPU Throttling',
      description='Cgroups that are getting CPU throttled. If the cgroup is not visible it is not getting throttled.',
      query=|||
        rate(
          container_cpu_cfs_throttled_seconds_total{%(selector)s}[$__rate_interval]
        ) > 0
      ||| % { selector: selector },
      interval='1m',
      linewidth=1,
      legendFormat='{{ id }}',
    ),

  MemoryUsagePerCGroup(selector)::
    basic.timeseries(
      title='cgroup: Memory per cgroup',
      description='RSS usage on every cgroup available on the Gitaly node.',
      query=|||
        topk(20, sum by (id) (container_memory_usage_bytes{%(selector)s}))
      ||| % { selector: selector },
      format='bytes',
      interval='1m',
      linewidth=1,
      legend_show=false,
      legendFormat='{{ id }}',
    ),

  MemoryQuantile(selector)::
    quantilePanel.timeseries(
      title='cgroup: Memory',
      description='P99/PX RRS usage of all cgroups available on the Gitaly node.',
      query=|||
        container_memory_usage_bytes{%(selector)s}
      ||| % { selector: selector },
      format='bytes',
      interval='1m',
      linewidth=1,
      legendFormat='cgroup: Memory',
    ),
}
