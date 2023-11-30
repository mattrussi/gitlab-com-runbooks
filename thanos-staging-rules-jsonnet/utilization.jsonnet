local utilizationMetrics = import 'servicemetrics/utilization-metrics.libsonnet';
local utilizationRules = import 'servicemetrics/utilization_rules.libsonnet';
local separateGlobalRecordingRuleFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;
local labelTaxonomy = import 'label-taxonomy/label-taxonomy.libsonnet';

local l = labelTaxonomy.labels;
local environmentLabels = labelTaxonomy.labelTaxonomy(l.environmentThanos | l.tier | l.service | l.stage);

separateGlobalRecordingRuleFiles(
  function(selector)
    utilizationRules.generateUtilizationRules(utilizationMetrics, environmentLabels=environmentLabels, extraSelector=selector),
  pathFormat='%(envName)s/%(baseName)s'
)
