local serviceCatalog = import 'service_catalog.libsonnet';

// Preferred ordering services on dashboards
local serviceOrdering = [
  'web',
  'git',
  'api',
  'ci-runners',
  'registry',
  'web-pages',
];

local keyServiceSorter(service) =
  local l = std.find(service.name, serviceOrdering);
  if l == [] then
    100
  else
    l[0];

{
  // Note, by having a overall_sla_weighting value, even if it is zero, the service will
  // be included on the SLA and MTBF dashboards. To remove it, delete the key
  keyServices::
    serviceCatalog.findServices(function(service)
      std.objectHas(service.business.SLA, 'overall_sla_weighting') && service.business.SLA.overall_sla_weighting >= 0),

  sortedKeyServices::
    std.sort(self.keyServices, keyServiceSorter),
}
