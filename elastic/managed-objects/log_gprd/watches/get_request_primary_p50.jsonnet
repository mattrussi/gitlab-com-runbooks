local watcher = import 'watcher.libsonnet';

watcher.percentileThresholdAlert(
  title='Rails GET endpoints that communicate excessively with the postgres primary',
  identifier=std.thisFile,
  scheduleHours=24,
  keyField='json.meta.caller_id.keyword',
  percentileValueField='json.db_primary_count',
  thresholdValue=2,
  elasticsearchIndexName='rails',
  emoji=':rails:',
  unit=' primary queries',
  queryFilters=[{
    match_phrase: {
      'json.method.keyword': 'GET',
    },
  }],

  // Link to the Rails Endpoint Dashboard
  extraDetail=|||
    :chart_with_upwards_trend: <https://log.gprd.gitlab.net/app/dashboards#/view/db37b560-9793-11eb-a990-d72c312ff8e9?_g=(filters:!((query:(match_phrase:(json.meta.caller_id:'{{#url}}{{key}}{{/url}}')))),time:(from:now-24h,to:now))|Rails Endpoint Dashboard>
  |||

)
