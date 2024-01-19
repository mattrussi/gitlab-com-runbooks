local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;
local serviceOpsAnomalyDetection = import 'recording-rules/service-ops-anomaly-detection.libsonnet';
local defaultsForRecordingRuleGroup = { partial_response_strategy: 'warn' };

local aggregationSet = (import 'gitlab-metrics-config.libsonnet').aggregationSets.serviceSLIs;

local outputPromYaml(groups) =
  std.manifestYamlDoc({
    groups: std.map(function(g) defaultsForRecordingRuleGroup + g, groups),
  });

separateGlobalRecordingFiles(
  function(selector)
    {
      service_ops_anomaly_detection: outputPromYaml(
        serviceOpsAnomalyDetection.recordingRuleGroupsFor('GitLab.com', aggregationSet, selector)
      ),
    }
)
