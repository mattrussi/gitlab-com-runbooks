local patroniCauseAlerts = import 'alerts/patroni-cause-alerts.libsonnet';
local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;

separateGlobalRecordingFiles(
  function(selector)
    {
      'patroni-cause-alerts': std.manifestYamlDoc(patroniCauseAlerts(selector)),
    }
)
