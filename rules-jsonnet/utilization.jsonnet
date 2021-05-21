local utilizationMetrics = import './utilization-metrics.libsonnet';
local utilizationRules = import 'servicemetrics/utilization_rules.libsonnet';

utilizationRules.generateUtilizationRules(utilizationMetrics)
