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

#### Monitoring Metrics

- CPU/Memory usage per runner
- Queue length trends
- Concurrent job counts

### Warning Signs

- Sustained high concurrency
- Repetitive job patterns
- Increasing queue depths
- Resource exhaustion indicators

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

## Dependencies

### Internal Dependencies

- GitLab Rails application
- CI/CD Runner infrastructure
- Redis/Sidekiq queuing system
- Database services

### External Dependencies

- Cloud provider resources
- External runner connections

## Definitions

- **Alert Definition**: [CI/CD Alert Definitions](../alerts/definitions.md)
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
