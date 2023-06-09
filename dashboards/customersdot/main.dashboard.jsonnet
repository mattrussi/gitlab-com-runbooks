local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';

serviceDashboard.overview('customersdot')
.addAnnotation(commonAnnotations.deploymentsForCustomersDot)
.overviewTrailer()
