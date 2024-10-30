local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local row = grafana.row;
local dashboardHelpers = import 'stage-groups/verify-runner/dashboard_helpers.libsonnet';

dashboardHelpers.dashboard(
  'performance',
  tags=[]
)