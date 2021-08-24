local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

local findServiceTypes(predicate) =
  local matchingServices = std.filter(predicate, metricsCatalog.services);
  local types = std.map(function(s) s.type, matchingServices);
  std.set(types);

local ensureFirst(default, types) =
  [default] + std.filter(function(f) f != default, types);

{
  goServices: std.set([
    'api',
    'git',
    'gitaly',
    'kas',
    'monitoring',
    'praefect',
    'registry',
    'web-pages',
    'web',
    'websockets',
  ]),

  // Disk utilisation metrics are currently reporting incorrectly for
  // HDD volumes, see https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10248
  // as such, we only record this utilisation metric on IO subset of the fleet for now.
  diskPerformanceSensitiveServices:: ['patroni', 'gitaly'],

  kubeProvisionedServices:: findServiceTypes(function(s) s.provisioning.kubernetes),
  kubeOnlyServices:: findServiceTypes(function(s) s.provisioning.kubernetes && !s.provisioning.vms),

  vmProvisionedServices(default)::
    ensureFirst(default, findServiceTypes(function(s) s.provisioning.vms)),
}
