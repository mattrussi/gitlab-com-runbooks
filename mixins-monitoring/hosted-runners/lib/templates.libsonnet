local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local templates = import 'grafana/templates.libsonnet';

local template = grafana.template;

{
  runnerManager::
    template.new(
      'shard',
      '$PROMETHEUS_DS',
      query=|||
        label_values(gitlab_runner_version_info,shard)
      |||,
      current='All',
      refresh='time',
      sort=true,
      multi=false,
      includeAll=false
    ),
}
