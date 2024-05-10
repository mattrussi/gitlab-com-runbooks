{
  // https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/observability/observability-tenants/-/blob/main/grafana.tf?ref_type=heads#L5
  mimirDatasource(tenant):: 'Mimir - %(tenant)s' % tenant,
}
