local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local kubeCauseAlerts = import 'alerts/kube-cause-alerts.libsonnet';

separateMimirRecordingFiles(
  function(service, selector, extraArgs)
    {
      'kube-cause-alerts': std.manifestYamlDoc(kubeCauseAlerts(selector)),
    }
)
