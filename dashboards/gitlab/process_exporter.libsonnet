local basic = import 'basic.libsonnet';
local layout = import 'layout.libsonnet';

/*
groupname, serviceType, serviceStage
              environment="$environment",
              groupname="%(groupname)s",
              type="%(serviceType)s",
              stage="%(serviceStage)s"
*/

{
  namedGroup(title, selector, aggregator, legendFormat, startRow)::
    local formatConfig = {
      selector: selector,
      aggregator: aggregator,
    };

    layout.grid([
      basic.timeseries(
      title='Process CPU Time',
      description='Seconds of CPU time for the named process group, per second',
      query=|||
        sum(
          rate(
            namedprocess_namegroup_cpu_seconds_total{%(selector)s}[$__interval]
          )
        ) by (%(aggregator)s)
      ||| % formatConfig,
      legendFormat='{{ fqdn }}',
      interval='1m',
      intervalFactor=1,
      format='s',
      legend_show=false,
      linewidth=1
    ),
    basic.timeseries(
      title=title + ': Open File Descriptors',
      description='Maximum number of open file descriptors per host',
      query=|||
        max(
          namedprocess_namegroup_open_filedesc{%(selector)s}
        ) by (%(aggregator)s)
      ||| % formatConfig,
      legendFormat='{{ fqdn }}',
      interval='1m',
      intervalFactor=1,
      legend_show=false,
      linewidth=1
    ),
    basic.timeseries(
      title=title + ': Number of Threads',
      description='Number of threads in the process group',
      query=|||
        sum(
          namedprocess_namegroup_num_threads{%(selector)s}
        ) by (%(aggregator)s)
      ||| % formatConfig,
      legendFormat='{{ fqdn }}',
      interval='1m',
      intervalFactor=1,
      legend_show=false,
      linewidth=1
    ),
    basic.timeseries(
      title=title + ': Memory Usage',
      description='Memory usage for named process group',
      query=|||
        sum(
          namedprocess_namegroup_memory_bytes{%(selector)s}
        ) by (%(aggregator)s)
      ||| % formatConfig,
      legendFormat='{{ fqdn }}',
      interval='1m',
      format='bytes',
      intervalFactor=1,
      legend_show=false,
      linewidth=1
    ),

    ], startRow=startRow),
}
