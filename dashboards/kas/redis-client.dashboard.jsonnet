local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';

local env_stage_app = 'env="$environment", stage="$stage", app="kas"';

basic.dashboard(
  'Redis client metrics',
  tags=[
    'kas',
  ],
)
.addTemplate(templates.stage)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Connection found in pool',
      description='Number of times a connection was found in the pool',
      query=|||
        sum (increase(redis_pool_hit_total{%s}[$__rate_interval]))
      ||| % env_stage_app,
      yAxisLabel='times',
      legend_show=false,
    ),
    basic.timeseries(
      title='Connection not found in pool',
      description='Number of times a connection was not found in the pool',
      query=|||
        sum (increase(redis_pool_miss_total{%s}[$__rate_interval]))
      ||| % env_stage_app,
      yAxisLabel='times',
      legend_show=false,
    ),
    basic.timeseries(
      title='Timeout retrieving connection from pool',
      description='Number of times a timeout occurred when looking for a connection in the pool',
      query=|||
        sum (increase(redis_pool_timeout_total{%s}[$__rate_interval]))
      ||| % env_stage_app,
      yAxisLabel='times',
      legend_show=false,
    ),
    basic.timeseries(
      title='Number of idle connections in pool',
      description='Current number of idle connections in the pool',
      query=|||
        sum (redis_pool_conn_idle_current{%s})
      ||| % env_stage_app,
      yAxisLabel='connections',
      legend_show=false,
    ),
    basic.timeseries(
      title='Removed stale connections',
      description='Number of times a connection was removed from the pool because it was stale',
      query=|||
        sum (increase(redis_pool_conn_stale_total{%s}[$__rate_interval]))
      ||| % env_stage_app,
      yAxisLabel='connections',
      legend_show=false,
    ),
  ], cols=3, rowHeight=10)
)
