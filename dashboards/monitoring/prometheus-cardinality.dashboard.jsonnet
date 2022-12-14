local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

basic.dashboard(
  'Prometheus Cardinality Metrics',
  tags=['monitoring'],
  editable=true,
  description='Dashboard for Prometheus Cardinality'
)
.addPanels(
  layout.singleRow([
    basic.multiTimeseries(
      title='The total number of samples scraped',
      description='Number of samples scraped',
      queries=[
        {
          legendFormat: 'Number of samples scraped',
          query: 'sum(scrape_samples_scraped{env="$environment"})',
        },
        {
          legendFormat: 'Number of samples scraped last week',
          query: '(sum(scrape_samples_scraped{env="$environment"} offset 1w))',

        },
      ],
      interval='1m',
      intervalFactor=3,
      yAxisLabel='Count',
      legend_show=true,
      linewidth=2,
      decimals=0,
      thresholds=[],
    ),
  ])
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Samples scraped in k8s',
      description='The number of samples the target exposed by type and job.',
      query='sum by (job, type, deployment, app) (scrape_samples_scraped{env="$environment", deployment!=""})',
      legendFormat='Type: {{type}} - Job: {{job}}',
      interval='5m',
      yAxisLabel='Count',
      sort='desc',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Samples scraped in chef-managed VMs',
      description='The number of samples the target exposed by type and job.',
      query='sum by (job, type, deployment, app) (scrape_samples_scraped{env="$environment", deployment="", type!=""})',
      legendFormat='Type: {{type}} - Job: {{job}}',
      interval='5m',
      sort='desc',
      yAxisLabel='Count',
      linewidth=2,
      legend_show=true,
    ),
  ], cols=2, rowHeight=10, startRow=2)
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Scrape series added in k8s',
      description='The number of samples the target exposed by type and job.',
      query='sum by (job, type, deployment, app) (scrape_series_added{env="$environment", deployment!=""})',
      legendFormat='Type: {{type}} - Job: {{job}}',
      sort='desc',
      interval='5m',
      yAxisLabel='Count',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Scrape series added in chef-managed VMs',
      description='',
      query='sum by (job, type, deployment, app) (scrape_series_added{env="$environment", deployment="", type!=""})',
      legendFormat='Type: {{type}} - Job: {{job}}',
      sort='desc',
      interval='5m',
      yAxisLabel='Count',
      legend_show=true,
      linewidth=2
    ),
  ], cols=2, rowHeight=10, startRow=3)
)
