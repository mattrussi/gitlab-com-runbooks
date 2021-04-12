local watcher = import 'watcher.libsonnet';

watcher.percentileThresholdAlert(
  title=|||
    *Rails Memory Usage per Endpoint*

    These endpoints consistently use a lot of memory. Excessive memory usage can have multiple consequences, including
    slowing down other requests running in the same process, excesssively long GC pauses, or even OOMs. Additionally,
    these requests may fail on smaller memory-constrained GitLab instances.
  |||,
  identifier=std.thisFile,
  percentile=99,  // "If we have requests that can allocate 1GB, this is clearly bad. As this increases pressure for all, and each GC cycle costs a ton" -- @ayufan
  scheduleHours=24,
  schedule={ daily: { at: '02:32' } },
  keyField='json.meta.caller_id.keyword',
  percentileValueField='json.mem_bytes',
  thresholdValue=300 * (1024 * 1024),  // 300 MiB
  elasticsearchIndexName='rails',
  emoji=':memory:',
  unit=' MiB',
  displayUnitDivisionFactor=1024 * 1024,  // Display in MiB, not bytes
  includeRailsEndpointDashboardLink=true
)
