local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;

// local seriesOverrides = import 'series_overrides.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
// local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
// local colors = import 'colors.libsonnet';
// local platformLinks = import 'platform_links.libsonnet';
// local capacityPlanning = import 'capacity_planning.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
// local redisCommon = import 'redis_common_graphs.libsonnet';
// local nodeMetrics = import 'node_metrics.libsonnet';
// local keyMetrics = import 'key_metrics.libsonnet';
// local serviceCatalog = import 'service_catalog.libsonnet';
// local row = grafana.row;
// local template = grafana.template;
// local graphPanel = grafana.graphPanel;
// local annotation = grafana.annotation;
local text = grafana.text;

dashboard.new(
  '2019-10-13 October 13 / Sunday night Crypto Miner Limit Takedown',
  schemaVersion=16,
  tags=['rca'],
  timezone='utc',
  graphTooltip='shared_crosshair',
  time_from='2019-10-13 12:00:00',
  time_to='2019-10-14 02:00:00',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanels(layout.grid([

  // ------------------------------------------------------

  text.new(title='CPU utilization on patroni-02, the postgres primary',
  mode='markdown',
  content='
# This graph shows how this incident applied CPU saturation pressure to our Postgres primary database. This had a knock-on effect to the rest of the site.
  '),
  basic.saturationTimeseries(
    title="Postgres Primary Average CPU Utilization",
    query='
      avg(instance:node_cpu_utilization:ratio{fqdn="patroni-02-db-gprd.c.gitlab-production.internal", environment="gprd"}) by (fqdn)

    ',
    legendFormat='{{ fqdn }}',
  ),


  // ------------------------------------------------------

  text.new(title='P',
  mode='markdown',
  content='
# Some CI pipeline worker queries slowed down, putting pressure on the Postgres primary and slowing down Sidekiq jobs that ran them
  '),
    basic.latencyTimeseries(
      title="ExpireJobCacheWorker,StageUpdateWorker latency ",
      description="p90 Processing time for ExpireJobCacheWorker,StageUpdateWorker pipeline (CI) jobs",
      query='
        histogram_quantile(0.9, sum(rate(sidekiq_jobs_completion_time_seconds_bucket{worker=~"ExpireJobCacheWorker|StageUpdateWorker", environment="gprd", env="gprd"}[$__interval])) by (le, worker))
      ',
      legendFormat='{{ worker }}',
      format='s',
      interval="1m",
      linewidth=1,
      intervalFactor=5,
    ),



  // ------------------------------------------------------

  text.new(title='Sidekiq queue lengths',
  mode='markdown',
  content='
# As sidekiq slowed down, thousands of duplicate jobs were queued up

https://gitlab.com/gitlab-com/gl-infra/scalability/issues/42 is intended to address this issue
  '),
    basic.queueLengthTimeseries(
      title="Sidekiq Queue Lengths per Queue",
      description="The number of jobs queued up to be executed. Lower is better",
      query='
        max_over_time(sidekiq_queue_size{environment="gprd"}[$__interval]) and on(fqdn) (redis_connected_slaves != 0)
      ',
      legendFormat='{{ name }}',
      format='short',
      interval="1m",
      linewidth=1,
      intervalFactor=3,
      yAxisLabel='Queue Length',
    ),

], cols=2, rowHeight=10, startRow=1))
+ {
  annotations: {
    list+: [
{
      datasource: "Pagerduty",
      enable: true,
      hide: false,
      iconColor: "#F2495C",
      limit: 100,
      name: "GitLab Production Pagerduty",
      serviceId: "PATDFCE",
      showIn: 0,
      tags: [],
      type: "tags",
      urgency: "high",
    },
    {
      datasource: "Pagerduty",
      enable: true,
      hide: false,
      iconColor: "#C4162A",
      limit: 100,
      name: "GitLab Production SLO",
      serviceId: "P7Q44DU",
      showIn: 0,
      tags: [],
      type: "tags",
      urgency: "high",
    },
    {
      datasource: "Simple Annotations",
      enable: true,
      hide: false,
      iconColor: "#5794F2",
      limit: 100,
      name: "Key Events",
      // To be completed...
      queries: [
      ], // { date: "2019-08-14T08:25:00Z", text: "The patroni postgres cluster manager on the primary database instance (pg01) reports 'ERROR: get_cluster'" },
      showIn: 0,
      tags: [],
      type: "tags",
    },
],
  },
}
