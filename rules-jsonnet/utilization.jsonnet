local labelTaxonomy = import 'label-taxonomy/label-taxonomy.libsonnet';
local utilizationMetrics = import 'servicemetrics/utilization-metrics.libsonnet';
local utilizationRules = import 'servicemetrics/utilization_rules.libsonnet';

local l = labelTaxonomy.labels;
local environmentLabels = labelTaxonomy.labelTaxonomy(l.environment | l.tier | l.service | l.stage);

utilizationRules.generateUtilizationRules(utilizationMetrics, environmentLabels=environmentLabels)
