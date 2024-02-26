local misc = import 'utils/misc.libsonnet';
local objects = import 'utils/objects.libsonnet';

local defaultPathFormat(serviceDefinition) = if misc.isPresent(serviceDefinition) then
  '%(tenantName)s/%(envName)s/%(serviceName)s/%(baseName)s.yml'
else
  '%(tenantName)s/%(envName)s/%(baseName)s.yml';

// namespaceFormat generates a namespace such as gitlab-gprd-gprd-cloudflare-utilization
local namespaceFormat(tenant, env, serviceDefinition, baseName) =
  local service =
    if misc.isPresent(serviceDefinition)
    then serviceDefinition.type
    else null;
  std.join('-', std.prune([tenant, env, service, baseName]));

{
  separateMimirRecordingFiles(
    filesForSeparateSelector,
    serviceDefinition=null,
    extraArgs={},
    metricsConfig=(import 'gitlab-metrics-config.libsonnet'),
    pathFormat=defaultPathFormat(serviceDefinition),
  )::
    local serviceTenants =
      if serviceDefinition == null
      then ['gitlab-gprd', 'gitlab-gstg', 'gitlab-ops', 'gitlab-pre']
      else std.get(serviceDefinition, 'tenants', []);
    local tenants =
      if std.length(serviceTenants) == 0
      then std.objectFields(metricsConfig.separateMimirRecordingSelectors)
      else std.filter(
        function(tenant) std.member(serviceTenants, tenant),
        std.objectFields(metricsConfig.separateMimirRecordingSelectors)
      );
    std.foldl(
      function(memo, tenantName)
        memo + objects.transformKeys(
          function(baseName)
            local envName = metricsConfig.separateMimirRecordingSelectors[tenantName].envName;
            local namespace = namespaceFormat(tenantName, envName, serviceDefinition, baseName);
            pathFormat % {
              // Mimir implicitly uses the filename as a namespace
              // so baseName follows the pattern gitlab-gprd-gprd-cloudflare-utilization
              baseName: namespace,
              tenantName: tenantName,
              envName: envName,
              serviceName: serviceDefinition.type,
            },
          filesForSeparateSelector(serviceDefinition, metricsConfig.separateMimirRecordingSelectors[tenantName].selector, extraArgs)
        ),
      tenants,
      {},
    ),
}
