local patroniCauseAlerts = import 'alerts/patroni-cause-alerts.libsonnet';
local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;

// See https://thanos.io/v0.34/components/query.md/#partial-response
local presentThanosRuleGroup(ruleGroup) = ruleGroup { partial_response_strategy: 'warn' };

separateGlobalRecordingFiles(
  function(selector)
    {
      'patroni-cause-alerts': std.manifestYamlDoc({ groups: std.map(presentThanosRuleGroup, patroniCauseAlerts(selector).groups) }),
    }
)
