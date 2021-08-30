local kubeDashboards = import 'gitlab-monitoring/gitlab-dashboards/kube_service_dashboards.libsonnet';

kubeDashboards.dashboardsForService('kas')
