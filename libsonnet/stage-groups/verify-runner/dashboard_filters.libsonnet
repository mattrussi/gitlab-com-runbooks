local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local runnersService = (import 'metrics-catalog.libsonnet').getService('ci-runners');

local shard = template.new(
  'shard',
  '$PROMETHEUS_DS',
  query=|||
    label_values(gitlab_runner_version_info{job=~".*",job!~"omnibus-runners|gprd-runner",shard!="default"}, shard)
  |||,
  current=null,
  refresh='load',
  sort=true,
  multi=true,
  includeAll=true,
);

local runnerManager = template.new(
  'runner_manager',
  '$PROMETHEUS_DS',
  query=|||
    query_result(label_replace(gitlab_runner_version_info{shard=~"$shard"}, "fqdn", "$1.*", "instance", "(.*):[0-9]+$"))
  |||,
  regex='/fqdn="([^"]+)"/',
  current=null,
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true,
);

local runnerJobFailureReason = template.new(
  'runner_job_failure_reason',
  '$PROMETHEUS_DS',
  query=|||
    label_values(gitlab_runner_failed_jobs_total, failure_reason)
  |||,
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true,
);

local jobsRunningForProject = template.new(
  'jobs_running_for_project',
  '$PROMETHEUS_DS',
  query=|||
    label_values(job_queue_duration_seconds_sum, jobs_running_for_project)
  |||,
  current='0',
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true
);

local gcpExporter = template.new(
  'gcp_exporter',
  '$PROMETHEUS_DS',
  query=|||
    label_values(gcp_exporter_region_quota_limit, instance)
  |||,
  refresh='load',
  sort=1,
  multi=false,
  includeAll=false
);

local gcpProject = template.new(
  'gcp_project',
  '$PROMETHEUS_DS',
  query=|||
    label_values(gcp_exporter_region_quota_limit, project)
  |||,
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true,
);

local gcpRegion = template.new(
  'gcp_region',
  '$PROMETHEUS_DS',
  query=|||
    label_values(gcp_exporter_region_quota_usage, region)
  |||,
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true,
);

local selectorHash = {
  type: runnersService.type,
  tier: runnersService.tier,
  stage: '$stage',
  environment: '$environment',
};

{
  shard:: shard,
  runnerManager:: runnerManager,
  runnerJobFailureReason:: runnerJobFailureReason,
  jobsRunningForProject:: jobsRunningForProject,
  gcpExporter:: gcpExporter,
  gcpProject:: gcpProject,
  gcpRegion:: gcpRegion,

  selectorHash:: selectorHash,
}
