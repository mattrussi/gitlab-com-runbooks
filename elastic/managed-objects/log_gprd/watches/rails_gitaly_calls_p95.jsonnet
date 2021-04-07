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
)
