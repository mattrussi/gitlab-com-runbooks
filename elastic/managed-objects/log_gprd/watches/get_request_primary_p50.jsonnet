local watcher = import 'watcher.libsonnet';

watcher.percentileThresholdAlert(
  title='Rails GET endpoints that communicate excessively with the postgres primary',
  identifier=std.thisFile,
  scheduleHours=24,
  schedule={ daily: { at: '02:12' } },
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
  includeRailsEndpointDashboardLink=true
)
