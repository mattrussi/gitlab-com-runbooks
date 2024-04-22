local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;
local recordingRuleRegistry = import 'servicemetrics/recording-rule-registry.libsonnet';
local sidekiqQueueRules = import 'recording-rules/sidekiq-queue-rules.libsonnet';

local rules(extraSelector) = {
  groups: [{
    name: 'Sidekiq Aggregated Thanos Alerts',
    partial_response_strategy: 'warn',
    interval: '1m',
    rules: sidekiqQueueRules.sidekiqPerWorkerAlertRules(recordingRuleRegistry.selectiveRegistry, extraSelector),
  }],
};

separateGlobalRecordingFiles(function(selector) {
  'sidekiq-alerts': std.manifestYamlDoc(rules(selector)),
})
