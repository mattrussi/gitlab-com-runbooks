local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';

serviceDashboard.overview('ci-runners')
.overviewTrailer()
