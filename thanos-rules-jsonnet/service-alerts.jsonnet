local alerts = import 'alerts/alerts.libsonnet';
local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;
local serviceAnomalyDetectionAlerts = import 'alerts/service-anomaly-detection-alerts.libsonnet';

separateGlobalRecordingFiles(
  function(selector)
    {
      'service-alerts': std.manifestYamlDoc({
        groups: [
          {
            name: 'slo_alerts.rules',
            partial_response_strategy: 'warn',
            rules: alerts.processAlertRules(serviceAnomalyDetectionAlerts(selector)),
          },
        ],
      }),
    }
)
