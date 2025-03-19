local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';
local template = grafana.template;

local useTimeSeriesPlugin = true;

basic.dashboard(
  'Worker Concurency Detail',
  tags=['type:sidekiq', 'detail'],
)
.addTemplate(templates.stage)
.addTemplate(template.new(
  'worker',
  '$PROMETHEUS_DS',
  'label_values(sidekiq_concurrency_limit_current_concurrent_jobs_total{environment="$environment", type="sidekiq"}, worker)',
  current='.*',
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true,
  allValues='.*',
))
.addPanels(
  layout.grid(
    if useTimeSeriesPlugin then
      [
        panel.timeSeries(
          title='Concurrency limit queue sizes',
          query=|||
            max by (worker) (
              idelta(
                sidekiq_concurrency_limit_queue_jobs_total{environment="$environment", type="sidekiq", stage="$stage", worker=~"$worker"}[$__interval]
              )
            )
          |||,
          interval='1m',
          linewidth=1,

          legend_show=true,
        ),
        panel.timeSeries(
          title='Worker concurrency',
          query=|||
            max by (worker) (
              idelta(
                sidekiq_concurrency_limit_current_concurrent_jobs_total{environment="$environment", type="sidekiq", stage="$stage", worker=~"$worker"}[$__interval]
              )
            )
          |||,
          interval='1m',
          linewidth=1,
          legend_show=true,
        ),
        panel.timeSeries(
          title='Worker deferment rate',
          query=|||
            sum by (worker) (
              rate(
                sidekiq_concurrency_limit_deferred_jobs_total{environment="$environment", type="sidekiq", stage="$stage", worker=~"$worker"}[$__interval]
              )
            )
          |||,
          interval='1m',
          linewidth=1,
          legend_show=true,
        ),
        panel.timeSeries(
          title='Concurrency limits',
          query=|||
            max by (worker) (
              sidekiq_concurrency_limit_max_concurrent_jobs{environment="$environment", type="sidekiq", stage="$stage", worker=~"$worker"}
            )
          |||,
          interval='1m',
          linewidth=1,
          legend_show=true,
        ),
      ]
    else
      [
        basic.timeseries(
          title='Concurrency limit queue sizes',
          query=|||
            max by (worker) (
              idelta(
                sidekiq_concurrency_limit_queue_jobs_total{environment="$environment", type="sidekiq", stage="$stage", worker=~"$worker"}[$__interval]
              )
            )
          |||,
          interval='1m',
          linewidth=1,

          legend_show=true,
        ),
        basic.timeseries(
          title='Worker concurrency',
          query=|||
            max by (worker) (
              idelta(
                sidekiq_concurrency_limit_current_concurrent_jobs_total{environment="$environment", type="sidekiq", stage="$stage", worker=~"$worker"}[$__interval]
              )
            )
          |||,
          interval='1m',
          linewidth=1,
          legend_show=true,
        ),
        basic.timeseries(
          title='Worker deferment rate',
          query=|||
            sum by (worker) (
              rate(
                sidekiq_concurrency_limit_deferred_jobs_total{environment="$environment", type="sidekiq", stage="$stage", worker=~"$worker"}[$__interval]
              )
            )
          |||,
          interval='1m',
          linewidth=1,
          legend_show=true,
          lines=true
        ),
        basic.timeseries(
          title='Concurrency limits',
          query=|||
            max by (worker) (
              sidekiq_concurrency_limit_max_concurrent_jobs{environment="$environment", type="sidekiq", stage="$stage", worker=~"$worker"}
            )
          |||,
          interval='1m',
          linewidth=1,
          legend_show=true,
        ),
      ],
    cols=2,
  )
)
.trailer()
