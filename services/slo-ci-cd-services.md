# SLO and Error budget policy for CI/CD services on GitLab.com

This document describes the SLOs for services that serve data from Git repositories on GitLab.com

## Status: Draft
### Approval Date:
### Review Date:

## Service Overview
On Gitlab.com, the processing for the Verify (CI) and Release (CD and Release Automation) services exist as a set of job runners.  There are shared runners for all users and another set of runners dedicated to GitLab EE and CE.  There are also dedicated private runners for specific internal GitLab projects.  Lastly, customers can create and attach dedicated runners for their own projects.

For a detailed design of the infrastructure for the CI/CD hosts- see [handbook link tbd].
Current gdoc:  https://docs.google.com/document/d/1WYmN5oukY3DK2hPFLPkxwnuyfxES8nNPeDLMTN_KhVM/edit#

The SLO uses a four week rolling window.

## SLIs and SLOs

### Runner jobs Latency

We will set a latency SLO on p90 and p95 for jobs via the Job queue timings metrics.  The SLO will be a p90 of 15 seconds and p95 of 25s.

https://dashboards.gitlab.net/d/000000159/ci?refresh=5m&orgId=1&from=1544515200000&to=1544522400000&panelId=89&fullscreen

histogram_quantile(0.95, sum(rate(job_queue_duration_seconds_bucket{environment="gprd", shared_runner="true"}[1d])) by (le))
histogram_quantile(0.90, sum(rate(job_queue_duration_seconds_bucket{environment="gprd", shared_runner="true"}[1d])) by (le))

Example Days

|Date        | p90 (s) | p95 (s) |
|--------------------|---------|-----|
|2019-01-24T20:00:00Z| 12.9 | 30 |
|2019-01-23T20:00:00Z| 7.3  | 22.2 |
|2019-01-22T20:00:00Z| 8.0  | 28.8 |
|2019-01-21T20:00:00Z| 15.7 | 30 |
|2019-01-17T20:00:00Z| 5.1  | 19.2 |
|2019-01-16T20:00:00Z| 5.9  | 24 |
|2019-01-15T20:00:00Z| 7.7  | 28.5 |
|2019-01-14T20:00:00Z| 12.3 | 30 |


### Runner success

We will set a SLO for job failures on runners.  Failures due to runner_system_failure will be tracked with a success ratio of 99%.  Failures due to job_execution timeout may be due to user error and will not be counted against the SLO.

We will also set an SLO of 95% for successful runs where there is not an error.

Error: sum(increase(gitlab_runner_errors_total{job="shared-runners-gitlab-org", level!="warning"}[7d]))
Failures: sum(increase(gitlab_runner_failed_jobs_total{job="shared-runners-gitlab-org", failure_reason="runner_system_failure"}[7d]))
Total: sum(increase(gitlab_runner_jobs_total{job="shared-runners-gitlab-org"}[7d]))

Sample Data:

|Date                | Total   | Errors | Err Rate %| Failures | Failure Rate %|
|--------------------|---------|--------|-----|----------------|---------------|
|2019-01-25T22:00:00Z| 264332  | 12143  | 4.6 |  1150          | 0.4 |
|2019-01-18T20:00:00Z| 218877  | 6418   | 2.9 |  607           | 0.3 |
|2019-01-10T20:00:00Z| 235151  | 13185  | 5.6 |  864           | 0.4 |

## Rational


## Error Budget

The error budget policy is to be implemented once we have exceeded the budget.


## Clarification and Caveats

* Request metrics measured from the load balancer will not take into account situations where the load balancer does not ship metrics for various reasons - general network issues or availability issues with metric collection.

-------------------------------------------

# Error Budget Policy

### Goals
The goals of the policy are to:
1. Protect users from repeated SLO misses
2. Provide and incentive to balance reliability with improvements to the system and feature delivery

Non-Goals: The policy is not intended to be a punishment for missing SLO targets.  Halting change is not the goal, this policy gives teams a way to measure when we need to focus exclusively on reliability.


### SLO Miss Policy

If the service is performing at or above its SLO, then releases and maintenance will proceed according to our exisitng change management and release policies.

If the service has exceeded its error budget for the preceeding 4 week window, we will halt all planned maintenance changes other than production incident remediations until the service is back within its SLO.

The team must work on reliability if:

1. A change related to a planned C1-C4 change issue caused the service to exceed the error budget.
2. Mis-categoried errors or incidents fail to consume budget that would have caused the service to miss its SLO.

The team may continue to work on non-reliability if:

1.  The outage was caused by a Cloud Service Provider incident for which no extra redundancy would have provided cover.
2.  Miscategorized errors consume budget even though no users were impacted.

### Outage Policy
If a single incident consumes more that 20% of error budget over the 4 week rolling period, the team must conduct an RCA.  That RCA should contain at least one P1 action item to address the root cause.

### Escalation Policy

If there is a disagreement over application or calculation of the policy, the issue should be taken to the Director of Infrastructure or VP of Engineering to make a decision.


### Notes

Current alerts meant as guide for SLOs

CICDDegradatedCIConsulPrometheusCluster (0 active)
CICDGCPQuotaCriticalUsage (0 active)
CICDGCPQuotaHighUsage (0 active)
CICDJobQueueDurationUnderperformant (0 active)
CICDNamespaceWithConstantNumberOfLongRunningRepeatedJobs (0 active)
CICDNoJobsOnSharedRunners (0 active)
CICDRunnerMachineCreationRateHigh (0 active)
CICDRunnersCacheDown (0 active)
CICDRunnersCacheNginxDown (0 active)
CICDRunnersCacheServerHasTooManyConnections (0 active)
CICDRunnersConcurrentLimitCritical (0 active)
CICDRunnersConcurrentLimitHigh (0 active)
CICDRunnersManagerDown (0 active)
CICDSidekiqQueuesTooBig (0 active)
CICDTooManyArchivingTraceFailures (0 active)
CICDTooManyPendingBuildsOnSharedRunnerProject (0 active)
CICDTooManyPendingJobsPerNamespace (0 active)
CICDTooManyRunningJobsPerNamespaceOnSharedRunners (0 active)
CICDTooManyRunningJobsPerNamespaceOnSharedRunnersGitLabOrg (0 active)
CICDTooManyUsedFDs (0 active)
CICDWorkhorseQueuingUnderperformant (0 active)



sidekiq_queue_size{name="pipeline_processing:stage_update"}
histogram_quantile(0.5, sum(rate(job_queue_duration_seconds_bucket{environment=~"$gitlab_env", jobs_running_for_project=~"$jobs_running_for_project"}[5m])) by (shared_runner, jobs_running_for_project, le))

Example event where jobs were delayed
https://dashboards.gitlab.net/d/9GOIu9Siz/sidekiq-stats?orgId=1&from=1546273661973&to=1546277042851
https://dashboards.gitlab.net/d/000000159/ci?refresh=5m&panelId=89&fullscreen&edit&orgId=1&from=1546273200000&to=1546279200000
