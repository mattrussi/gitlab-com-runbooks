local watcher = import 'watcher.libsonnet';

watcher.percentileThresholdAlert(
  title='Rails p95 Redis duration per Endpoint',
  identifier=std.thisFile,
  scheduleHours=24,
  schedule={ daily: { at: '04:42' } },
  keyField='json.meta.caller_id.keyword',
  percentileValueField='json.redis_duration_s',
  thresholdValue=0.01,  // also the slowlog threshold
  elasticsearchIndexName='rails',
  emoji=':redis:',
  includeRailsEndpointDashboardLink=true
)
