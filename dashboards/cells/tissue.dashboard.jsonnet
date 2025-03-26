local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local mimirHelper = import 'services/lib/mimir-helpers.libsonnet';


basic.dashboard(
  'Tissue - Ring Deployments',
  tags=['delivery'],
  includeEnvironmentTemplate=false,
  includeStandardEnvironmentAnnotations=false,
  defaultDatasource=mimirHelper.mimirDatasource('gitlab-ops'),
)

.trailer()
