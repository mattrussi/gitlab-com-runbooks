local misc = import 'utils/misc.libsonnet';
local objects = import 'utils/objects.libsonnet';

local defaultPathFormat(serviceDefinition) = if misc.isPresent(serviceDefinition) then
  '%(tenantName)s/%(envName)s/%(serviceName)s/%(baseName)s.yml'
else
  '%(tenantName)s/%(envName)s/%(baseName)s.yml';

{
  separateMimirRecordingFiles(
    filesForSeparateSelector,
    serviceDefinition=null,
    extraArgs={},
    metricsConfig=(import 'gitlab-metrics-config.libsonnet'),
    pathFormat=defaultPathFormat(serviceDefinition),
  )::
    std.foldl(
      function(memo, tenantName)
        memo + objects.transformKeys(
          function(baseName)
            pathFormat % {
              baseName: baseName,
              tenantName: tenantName,
              envName: metricsConfig.separateMimirRecordingSelectors[tenantName].envName,
              serviceName: serviceDefinition.type,
            },
          filesForSeparateSelector(serviceDefinition, metricsConfig.separateMimirRecordingSelectors[tenantName].selector, extraArgs)
        ),
      std.objectFields(metricsConfig.separateMimirRecordingSelectors),
      {},
    ),
}
