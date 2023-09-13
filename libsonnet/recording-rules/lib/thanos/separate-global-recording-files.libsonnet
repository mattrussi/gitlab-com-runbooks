local objects = import 'utils/objects.libsonnet';

{
  separateGlobalRecordingFiles(
    filesForSeparateSelector,
    metricsConfig=(import 'gitlab-metrics-config.libsonnet')
  )::
    std.foldl(
      function(memo, groupName)
        memo + objects.transformKeys(
          function(baseName)
            '%s-%s.yml' % [baseName, groupName],
          filesForSeparateSelector(metricsConfig.separateGlobalRecordingSelectors[groupName])
        ),
      std.objectFields(metricsConfig.separateGlobalRecordingSelectors),
      {},
    ),
}
