local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local services = (import 'gitlab-metrics-config.libsonnet').monitoredServices;

std.foldl(
  function(memo, service)
    memo + {
      ['dashboards/%(type)s.json' % service]:
        serviceDashboard.overview(service.type)
        .overviewTrailer()
    },
  services,
  {}
)
