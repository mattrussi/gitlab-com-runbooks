local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

{
  new():: [
    {
      component: sliName,
      type: 'patroni',
    }
    for sliName in std.objectFields(metricsCatalog.getService('patroni').serviceLevelIndicators)
  ],
}
