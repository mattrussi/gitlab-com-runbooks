local watcher = import 'watcher.libsonnet';

watcher.percentileThresholdAlert(
  title='Worst performing Rails endpoints in the application, by p95 latency',
  identifier=std.thisFile,
  scheduleHours=24,
  schedule={ daily: { at: '02:22' } },
  keyField='json.meta.caller_id.keyword',
  percentileValueField='json.duration_s',
  thresholdValue=1,
  elasticsearchIndexName='rails',
  emoji=':rails:',
  includeRailsEndpointDashboardLink=true
)
