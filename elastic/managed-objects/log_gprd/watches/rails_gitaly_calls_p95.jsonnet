local watcher = import 'watcher.libsonnet';

watcher.percentileThresholdAlert(
  title='Rails p95 Gitaly calls per Endpoint',
  identifier=std.thisFile,
  scheduleHours=24,
  keyField='json.meta.caller_id.keyword',
  percentileValueField='json.gitaly_calls',
  thresholdValue=100,
  elasticsearchIndexName='rails',
  emoji=':gitaly:',
  unit=' gitaly calls',

  // Link to the Rails Endpoint Dashboard
  extraDetail=|||
    :chart_with_upwards_trend: <https://log.gprd.gitlab.net/app/dashboards#/view/db37b560-9793-11eb-a990-d72c312ff8e9?_g=(filters:!((query:(match_phrase:(json.meta.caller_id:'{{#url}}{{key}}{{/url}}')))),time:(from:now-24h,to:now))|Rails Endpoint Dashboard>
  |||
)
