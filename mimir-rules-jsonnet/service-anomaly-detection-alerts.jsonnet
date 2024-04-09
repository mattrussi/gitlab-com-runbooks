local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local selectors = import 'promql/selectors.libsonnet';
local alerts = import 'alerts/alerts.libsonnet';
local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local serviceAnomalyDetectionAlerts = import 'alerts/service-anomaly-detection-alerts.libsonnet';

local servicesWithOpsRatePrediction = std.filter(
  function(service) !service.disableOpsRatePrediction,
  monitoredServices
);

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: groups,
  });

local fileForService(service, extraSelector, _extraArgs) =
  local selector = selectors.merge(extraSelector, { type: service.type });
  {
    'service-anomaly-detection-alerts': outputPromYaml(
      [
        {
          name: '%s - service_ops_anomaly_detection' % service.type,
          rules: alerts.processAlertRules(serviceAnomalyDetectionAlerts(selector)),
        },
      ],
    ),
  };

std.foldl(
  function(memo, service)
    memo + separateMimirRecordingFiles(
      fileForService,
      service,
    ),
  servicesWithOpsRatePrediction,
  {}
)
