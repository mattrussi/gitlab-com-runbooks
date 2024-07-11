local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local templates = import 'grafana/templates.libsonnet';

local template = grafana.template;

{
  runnerManager::
    template.new(
      'runner',
      '$PROMETHEUS_DS',
      query=|||
        label_values(gitlab_runner_version_info,job)
      |||,
      current='All',
      refresh='time',
      sort=true,
      multi=true,
      includeAll=false
    ),
}
