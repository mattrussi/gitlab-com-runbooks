local utilizationMetrics = import 'gitlab-monitoring/servicemetrics/utilization-metrics.libsonnet';
local utilizationRules = import 'gitlab-monitoring/servicemetrics/utilization_rules.libsonnet';

utilizationRules.generateUtilizationRules(utilizationMetrics)
