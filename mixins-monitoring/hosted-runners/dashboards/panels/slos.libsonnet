local basic = import 'runbooks/libsonnet/grafana/basic.libsonnet';
local panel = import 'runbooks/libsonnet/grafana/time-series/panel.libsonnet';
local selectors = import 'runbooks/libsonnet/promql/selectors.libsonnet';

local overallAvailability(selector) =
  basic.statPanel(
    title='',
    panelTitle='Overall Availability',
    description="Percentage of ci_runner_jobs over the dashboard's range that did not have internal errors.",
    query=|||
      sum_over_time(sum by(component) (
        gitlab_service_ops:rate_1h{%(selector)s, component="ci_runner_jobs"} -  gitlab_service_errors:rate_1h{%(selector)s, component="ci_runner_jobs"}
      )[$__range:1m])
      /
      sum_over_time(
        sum by(component) (
          gitlab_service_ops:rate_1h{%(selector)s, component="ci_runner_jobs"}
        )[$__range:1m])
    ||| % { selector: selector },
    unit='percentunit',
    min=0,
    max=1,
    decimals=2,
    color=[
      { color: 'red', value: null },
      { color: 'light-red', value: 0.95 },
      { color: 'orange', value: 0.99 },
      { color: 'light-orange', value: 0.995 },
      { color: 'yellow', value: 0.9994 },
      { color: 'light-yellow', value: 0.9995 },
      { color: 'green', value: 0.9998 },
    ],
    graphMode='none',
    stableId='hosted-runners-overall-availability',
  );

local budgetSpent(selector) =
  basic.statPanel(
    title='',
    panelTitle='Availability Budget Spent',
    description="Estimated time over the dashboard's period where ci_runner_jobs failed due to internal errors",
    query=|||
      (
        1 - (
          sum_over_time(sum by(component) (
            gitlab_service_ops:rate_1h{%(selector)s, component="ci_runner_jobs"} -  gitlab_service_errors:rate_1h{%(selector)s, component="ci_runner_jobs"}
          )[$__range:1m])
          /
          sum_over_time(
            sum by(component) (
              gitlab_service_ops:rate_1h{%(selector)s, component="ci_runner_jobs"}
            )[$__range:1m])
        )
      ) * $__range_ms
    ||| % { selector: selector },
    unit='dtdurationms',
    min=0,
    decimals=0,
    color=[
      { color: 'red', value: null },
      { color: 'light-red', value: 0.95 },
      { color: 'orange', value: 0.99 },
      { color: 'light-orange', value: 0.995 },
      { color: 'yellow', value: 0.9994 },
      { color: 'light-yellow', value: 0.9995 },
      { color: 'green', value: 0.9998 },
    ],
    graphMode='none',
    stableId='hosted-runners-budget-spent',
  );

local rollingAvailability(selector) =
  panel.timeSeries(
    title='Rolling availability',
    description="Percentage of ci_runner_jobs over the dashboard's range that did not have internal errors, looking back over the dashboard's range window.",
    query=|||
      sum_over_time(sum by(component) (
        gitlab_service_ops:rate_1h{%(selector)s, component="ci_runner_jobs"} -  gitlab_service_errors:rate_1h{%(selector)s, component="ci_runner_jobs"}
      )[$__range:$__interval])
      /
      sum_over_time(
        sum by(component) (
          gitlab_service_ops:rate_1h{%(selector)s, component="ci_runner_jobs"}
        )[$__range:$__interval])
    ||| % { selector: selector },
    legendFormat='__auto',
    format='percentunit',
    min=0,
    max=1,
    fill=0,
    stableId='hosted-runners-rolling-availability'
  );

local jobQueuingSLO(selector) =
  basic.statPanel(
    title='',
    panelTitle='Job Queue Latency SLO',
    description="Percentage of all jobs over the dashboard's range that were executed within an acceptable time. Excludes jobs that were delayed because the scaleMax threshold was hit.",
    query=|||
      1 -
      sum(sum_over_time(
        (
          sum by (shard) (
            increase(
              (
                sum by (shard) (gitlab_runner_acceptable_job_queuing_duration_exceeded_total{%(selector)s})
              )[1m:1m]
            )
          ) *
          (
            min_over_time(
              (sum by(shard)(fleeting_provisioner_instances{%(selector)s, state!="deleting"}) < bool sum by(shard)(fleeting_provisioner_max_instances) * .9)[2m:1m]
            )
          )
        )[$__range:1m]
      )
      ) /
      increase(sum(gitlab_runner_jobs_total{%(selector)s})[$__range:1m])
    ||| % { selector: selector },
    unit='percentunit',
    min=0,
    max=1,
    decimals=2,
    color=[
      { color: 'red', value: null },
      { color: 'light-red', value: 0.95 },
      { color: 'orange', value: 0.99 },
      { color: 'light-orange', value: 0.995 },
      { color: 'yellow', value: 0.9994 },
      { color: 'light-yellow', value: 0.9995 },
      { color: 'green', value: 0.9998 },
    ],
    graphMode='none',
    stableId='job-queuing-slo',
  );

local queuingViolationsCount(selector) =
  basic.statPanel(
    title='',
    panelTitle='Jobs Violating Latency',
    description="Number of jobs over the dashboard's range that exceeded the acceptable time. Excludes jobs that were delayed because the scaleMax threshold was hit.",
    query=|||
      sum(sum_over_time(
        (
          sum by (shard) (
            increase(
              (
                sum by (shard) (gitlab_runner_acceptable_job_queuing_duration_exceeded_total{%(selector)s})
              )[1m:1m]
            )
          ) *
          (
            min_over_time(
              (sum by(shard)(fleeting_provisioner_instances{%(selector)s, state!="deleting"}) < bool sum by(shard)(fleeting_provisioner_max_instances) * .9)[2m:1m]
            )
          )
        )[$__range:1m]
      ))
    ||| % { selector: selector },
    unit='none',
    min=0,
    color='yellow',
    decimals=0,
    graphMode='none',
    stableId='job-queuing-violations-count',
  );

local jobQueuingSLOOverTime(selector) =
  panel.timeSeries(
    title='Job Queuing Latency SLO Over Time',
    description="Percentage of all jobs looking back over the dashboard's range that were executed within an acceptable time. Excludes jobs that were delayed because the scaleMax threshold was hit.",
    query=|||
      1 -
      sum(sum_over_time(
        (
          sum by (shard) (
            increase(
              (
                sum by (shard) (gitlab_runner_acceptable_job_queuing_duration_exceeded_total{%(selector)s})
              )[1m:1m]
            )
          ) *
          (
            min_over_time(
              (sum by(shard)(fleeting_provisioner_instances{%(selector)s, state!="deleting"}) < bool sum by(shard)(fleeting_provisioner_max_instances) * .9)[2m:1m]
            )
          )
        )[$__range:$__interval]
      )) /
      increase(sum(gitlab_runner_jobs_total{%(selector)s})[$__range:$__interval])
    ||| % { selector: selector },
    legendFormat='Job Queuing SLO',
    format='percentunit',
    min=0.9,
    max=1,
    fill=0,
    stableId='job-queuing-slo-over-time'
  );

{
  new(selectorHash):: {
    local selector = selectors.serializeHash(selectorHash),

    overallAvailability:: overallAvailability(selector),
    budgetSpent:: budgetSpent(selector),
    rollingAvailability:: rollingAvailability(selector),
    jobQueuingSLO:: jobQueuingSLO(selector),
    queuingViolationsCount:: queuingViolationsCount(selector),
    jobQueuingSLOOverTime:: jobQueuingSLOOverTime(selector),
  },
}
