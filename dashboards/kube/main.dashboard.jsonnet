local serviceDashboard = import 'gitlab-monitoring/gitlab-dashboards/service_dashboard.libsonnet';

serviceDashboard.overview('kube')
.overviewTrailer()
