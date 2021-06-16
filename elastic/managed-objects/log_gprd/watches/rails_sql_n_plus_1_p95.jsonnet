local watcher = import 'watcher.libsonnet';

watcher.percentileThresholdAlert(
  title='Rails p95 DB calls per Endpoint',
  identifier=std.thisFile,
  scheduleHours=24,
  schedule={ daily: { at: '02:52' } },
  keyField='json.meta.caller_id.keyword',
  percentileValueField='json.db_count',
  thresholdValue=100,
  elasticsearchIndexName='rails',
  emoji=':postgres:',
  unit=' db calls',
  includeRailsEndpointDashboardLink=true
)
