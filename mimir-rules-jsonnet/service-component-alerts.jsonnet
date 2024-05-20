local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local serviceAlertsGenerator = import 'slo-alerts/service-alerts-generator.libsonnet';
local alertGroupsForService = import 'alerts/service-component-alerts.libsonnet';

local fileForService(service, selector, _extraArgs) =
  local groups = alertGroupsForService(service, selector, aggregationSets);
  if groups != null then
    {
      'service-level-alerts': std.manifestYamlDoc(groups),
    }
  else {};

local servicesWithSlis = std.filter(
  function(service)
    std.length(service.listServiceLevelIndicators()) > 0,
  monitoredServices
);

std.foldl(
  function(memo, service)
    memo + separateMimirRecordingFiles(
      fileForService,
      service,
    ),
  servicesWithSlis,
  {}
)
