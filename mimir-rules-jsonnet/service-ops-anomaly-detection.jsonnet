local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local serviceOpsAnomalyDetection = import 'recording-rules/service-ops-anomaly-detection.libsonnet';
local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;

local serviceAggregation = (import 'mimir-aggregation-sets.libsonnet').serviceSLIs;

local outputPromYaml(groups) =
  std.manifestYamlDoc({ groups: groups });

local fileForService(service, selector, _extraArgs) = {
  service_ops_anomaly_detection: outputPromYaml(
    serviceOpsAnomalyDetection.recordingRuleGroupsFor(
      service.type, serviceAggregation, selector { type: service.type }
    )
  ),
};

std.foldl(
  function(memo, service)
    memo + separateMimirRecordingFiles(
      fileForService,
      service,
    ),
  monitoredServices,
  {}
)
