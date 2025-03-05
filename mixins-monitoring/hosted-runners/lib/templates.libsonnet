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

    fluentdPlugin::
        template.new(
            'plugin',
            '$PROMETHEUS_DS',
            query=|||
                label_values(fluentd_output_status_flush_time_count,plugin)
            |||,
            current='All',
            refresh='time',
            sort=true,
            multi=false,
            includeAll=false
        ),
}
