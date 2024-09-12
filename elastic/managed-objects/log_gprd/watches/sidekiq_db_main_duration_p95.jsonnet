local watcher = import 'watcher.libsonnet';

watcher.percentileThresholdAlert(
  title='Sidekiq p95 Main Primary DB query duration per Endpoint',
  identifier=std.thisFile,
  scheduleHours=24,
  schedule={ daily: { at: '03:02' } },
  keyField='json.class.keyword',
  index='pubsub-sidekiq-inf-gprd*',
  percentileValueField='json.db_main_duration_s',
  thresholdValue=60,
  elasticsearchIndexName='sidekiq',
  emoji=':postgres:',
  unit=' seconds',
  includeRailsEndpointDashboardLink=false
)
