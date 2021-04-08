local watcher = import 'watcher.libsonnet';

watcher.percentileThresholdAlert(
  title='Worst performing Rails endpoints in the application, by p95 latency',
  identifier=std.thisFile,
  scheduleHours=24,
  keyField='json.meta.caller_id.keyword',
  percentileValueField='json.duration_s',
  thresholdValue=1,
  elasticsearchIndexName='rails',
  emoji=':rails:',

  // Link to the Rails Endpoint Dashboard
  extraDetail=|||
    :chart_with_upwards_trend: <https://log.gprd.gitlab.net/app/dashboards#/view/db37b560-9793-11eb-a990-d72c312ff8e9?_g=(filters:!((query:(match_phrase:(json.meta.caller_id:'{{#url}}{{key}}{{/url}}')))),time:(from:now-24h,to:now))|Rails Endpoint Dashboard>
  |||
)
