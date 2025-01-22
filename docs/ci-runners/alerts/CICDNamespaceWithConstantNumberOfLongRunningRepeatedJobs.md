# CICDNamespaceWithConstantNumberOfLongRunningRepeatedJobs

**Table of Contents**

[TOC]

## Overview

### What does this alert mean?

This alert indicates potential abuse or unusual usage patterns in the CI/CD system where jobs within a specific namespace are:

- Running for extended periods
- Being repeatedly executed
- Showing patterns that deviate from normal CI/CD usage

### Contributing Factors

- Intentional abuse of CI/CD resources
- Misconfigured CI job definitions
- Unoptimized CI/CD pipelines causing resource strain
- Stuck jobs that keep restarting

### Service Impact

- Excessive consumption of shared runner resources
- Potential degradation of CI/CD performance for other users
- Increased system load and resource utilization
- Possible cost implications for cloud resources

### Required Actions

1. Investigate the flagged namespace using rails console
2. Analyze job patterns and resource consumption
3. Determine if activity is legitimate or abusive
4. Take appropriate action (blocking users, disabling runners, etc.)
5. Report confirmed abuse cases to the abuse team

## Services

- [CI Runners Service Overview](https://dashboards.gitlab.net/d/ci-runners-main/ci-runners-overview)
- **Team**: [Verify:Runner](https://handbook.gitlab.com/handbook/engineering/development/ops/verify/runner/)

## Metrics

### Core Metrics Monitoring

#### Primary Metrics

- `ci_runner_jobs_total`: Total number of CI jobs processed
  - Labels: `namespace_id`, `runner_type`, `job_status`
  - Used to track job execution patterns per namespace

- `ci_runner_job_duration_seconds`: Duration of CI jobs
  - Labels: `namespace_id`, `runner_type`, `job_name`
  - Helps identify unusually long-running jobs
  - Normal range: Most jobs complete within minutes to a few hours

#### Secondary Metrics

- `ci_runner_concurrent_jobs`: Number of concurrent jobs per runner
  - Helps identify resource consumption patterns
  - Alert triggers when consistently high over time

- `ci_runner_queue_duration_seconds`: Time jobs spend in queue
  - Indicates resource availability issues
  - Can signal potential abuse when artificially extended

### Threshold Configuration

#### Alert Triggers

- Primary conditions that trigger the alert:
  1. Jobs running longer than 3 hours consistently
  2. More than 10 identical jobs running simultaneously
  3. Repetition pattern exceeding normal usage (>50 similar jobs/hour)

#### Baseline Metrics

Normal operating conditions:

- Average job duration: 5-30 minutes
- Concurrent jobs per namespace: 1-5
- Job repetition rate: Variable based on project size
  - Small projects: 1-10 jobs/hour
  - Medium projects: 10-50 jobs/hour
  - Large projects: Custom thresholds based on agreed usage

### Visualization and Monitoring

#### Key Dashboards

1. **CI Runner Overview Dashboard**

   ```promql
   sum(rate(ci_runner_jobs_total{namespace_id="$namespace"}[5m]))
   by (job_name, runner_type)
   ```

    - Shows job execution rates
    - Helps identify unusual patterns
2. **Long-Running Jobs Dashboard**

   ```promql
   ci_runner_job_duration_seconds{namespace_id="$namespace"} > 10800
   ```

   - Identifies jobs exceeding 3-hour threshold
   - Groups by project and job type

### Resource Utilization Dashboard

#### Monitoring Metrics

- CPU/Memory usage per runner
- Queue length trends
- Concurrent job counts

### Warning Signs

- Sustained high concurrency
- Repetitive job patterns
- Increasing queue depths
- Resource exhaustion indicators

### Job Pattern Detection

    ```promql
    # Detect repeated identical jobs
    sum(
        increase(ci_runner_jobs_total{namespace_id="$namespace"}[1h])
    ) by (job_name) > 50
    ```

## Resource Impact Analysis

# Monitor runner resource consumption

    ```promql
    sum(
        rate(ci_runner_duration_seconds_sum{namespace_id="$namespace"}[5m])
    ) by (runner_type) /
    sum(
        rate(ci_runner_duration_seconds_count{namespace_id="$namespace"}[5m])
    ) by (runner_type)
    ```

## Alert Behavior

### Silencing Guidelines

- Only silence while actively investigating
- Maximum silence duration: 4 hours
- Document silence reason and investigation status

### Alert Frequency

- Should be relatively rare
- Multiple alerts for same namespace indicate urgent investigation needed

## Severities

### Initial Severity: S3

- Can be escalated based on impact assessment
- Consider upgrading severity if:
  - Multiple namespaces affected
  - Critical projects impacted
  - Resource exhaustion imminent

### Impact Assessment

- **External Impact**:
  - Other GitLab.com users sharing runners
  - Pipeline performance degradation
- **Internal Impact**:
  - Infrastructure costs
  - Resource availability
  - System stability

## Verification

### Investigation Steps

1. Connect to rails console:

    ```ruby
    ns = Namespace.find(1234567)
    ```

2. Check namespace details:

- Owner information
- Project count
- Activity patterns

3. Review CI/CD metrics:

- Job duration trends
- Resource consumption
- Failed job patterns

## Troubleshooting

### Basic Troubleshooting Steps

1. Identify problematic namespace
2. Review job configurations
3. Check resource utilization
4. Analyze job patterns

### Useful Commands

#### Cleanup Script for Pending Jobs

    ```bash
    PRIVATE_TOKEN=XXX
    GITLAB_URL=gitlab.com
    PROJECT_FULL_NAME=[user|group]%2f[project name]

    CURL_OUT=$(curl -f -s --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
    "https://$GITLAB_URL/api/v4/projects/$PROJECT_FULL_NAME/pipelines?status=pending")

    while [ $CURL_OUT != "[]" ]; do
    echo $CURL_OUT | jq -r '.[].id' | \
    awk -v GITLAB_URL=$GITLAB_URL \
        -v PROJECT_FULL_NAME=$PROJECT_FULL_NAME \
        '{print "https://"GITLAB_URL"/api/v4/projects/"PROJECT_FULL_NAME"/pipelines/"$1"/cancel"}'

    # ... rest of cleanup script

    done
    ```

### Common Resolution Steps

1. **For Abuse Cases**:
   - Block user access
   - Disable shared runners
   - Report to abuse team

2. **For Configuration Issues**:
   - Work with project owners
   - Optimize CI/CD configurations
   - Implement resource limits

3. **For System Issues**:
   - Clear stuck jobs
   - Reset runner states
   - Scale resources if needed

## Dependencies

### Internal Dependencies

- GitLab Rails application
- CI/CD Runner infrastructure
- Redis/Sidekiq queuing system
- Database services

### External Dependencies

- Cloud provider resources
- External runner connections

## Escalation

### Escalation Path

1. First response: SRE team
2. Secondary: CI/CD team
3. If abuse confirmed: Abuse team

### Communication Channels

- Primary: #ci-cd
- Secondary: #abuse
- Emergency: #production

## Definitions

- **Alert Definition**: [CI/CD Alert Definitions](../alerts/definitions.md)
- **Playbook Location**: \`/docs/ci-cd/alerts/CICDNamespaceWithConstantNumberOfLongRunningRepeatedJobs.md\`
- **Tuning Parameters**:
  - Job duration thresholds
  - Repetition detection settings
  - Resource consumption limits

## Related Links

- [CI/CD Runner Documentation](../README.md)
- [Runner Configuration Guide](../configuration.md)
- [Abuse Handling Procedures](../abuse-handling.md)
- [Resource Limits Documentation](../resource-limits.md)

**Sources:**

- [CI/CD Constant Number of Long Running, Repeated Jobs](https://gitlab.com/gitlab-com/runbooks/tree/master/docs/ci-runners/ci_constantnumberoflongrunningrepeatedjobs.md)
- [Alert Playbook Template](https://gitlab.com/gitlab-com/runbooks/tree/master/docs/template-alert-playbook.md)
