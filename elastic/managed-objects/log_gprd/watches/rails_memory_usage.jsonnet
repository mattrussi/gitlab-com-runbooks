local watcher = import 'watcher.libsonnet';

watcher.percentileThresholdAlert(
  title=|||
    *Rails Memory Usage per Endpoint*

    These endpoints consistently use a lot of memory. Excessive memory usage can have multiple consequences, including
    slowing down other requests running in the same process, excesssively long GC pauses, or even OOMs. Additionally,
    these requests may fail on smaller memory-constrained GitLab instances.
  |||,
  identifier=std.thisFile,
  scheduleHours=24,
  schedule={ daily: { at: '02:32' } },
  keyField='json.meta.caller_id.keyword',
  percentileValueField='json.mem_bytes',
  thresholdValue=80 * (1024 * 1024),  // 80 MiB
  elasticsearchIndexName='rails',
  emoji=':memory:',
  unit=' MiB',
  displayUnitDivisionFactor=1024 * 1024,  // Display in MiB, not bytes
  includeRailsEndpointDashboardLink=true
)
