local metricsConfig = import 'gitlab-metrics-config.libsonnet';
local strings = import 'utils/strings.libsonnet';

local mimirTenants = std.objectFields(metricsConfig.separateMimirRecordingSelectors);

{
  // https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/observability/observability-tenants/-/blob/main/grafana.tf?ref_type=heads#L5
  mimirDatasource(tenantId)::
    assert std.setMember(tenantId, mimirTenants) : 'invalid tenantId %s. Available tenants: %s' % [tenantId, mimirTenants];
    'Mimir - %(tenant)s' % strings.title(std.strReplace(tenantId, '-', ' ')),

  mimirTenants:: mimirTenants,
}
