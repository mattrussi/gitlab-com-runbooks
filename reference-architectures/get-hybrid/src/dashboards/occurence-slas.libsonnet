local occurenceSLADashboard = import 'gitlab-dashboards/occurrence-sla-dashboard.libsonnet';
local metricsConfig = import 'gitlab-metrics-config.libsonnet';

occurenceSLADashboard.dashboard(metricsConfig.keyServices, metricsConfig.aggregationSets.serviceSLIs)
