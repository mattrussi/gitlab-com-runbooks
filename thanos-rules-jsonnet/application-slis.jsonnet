local applicationSlisRules = import 'recording-rules/application-slis-rule-files.libsonnet';
local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;

separateGlobalRecordingFiles(
  function(selector) {
    'gitlab-application-slis':
      std.manifestYamlDoc(applicationSlisRules(selector)),
  },
)
