# CiRunnersServiceQueuingQueriesDurationApdexSLOViolation

**Table of Contents**

[TOC]

## Overview

This alert indicates that the CI Runners service is experiencing slower-than-expected queuing query response times, violating the defined Service Level Objectives (SLO) for job scheduling performance.

### Contributing Factors

- High volume of concurrent CI job requests
- Database performance issues
- Runner manager capacity constraints
- Resource exhaustion in the runner fleet

### Affected Components

- CI Runner job scheduling system
- Runner managers
- Database queries related to job queuing
- CI/CD pipeline execution times

### Expected Action

Investigate the cause of increased queuing duration and take appropriate action to restore normal service performance.

---

## Services

- [CI Runners Service Overview](https://dashboards.gitlab.net/d/ci-runners-main/ci-runners-overview)
- **Team**: [Verify:Runner](https://handbook.gitlab.com/handbook/engineering/development/ops/verify/runner/)

## Quick Links

- [Dashboard](https://dashboards.gitlab.net/goto/uXCF8OvNg?orgId=1)
- [List of users in the queue](https://log.gprd.gitlab.net/goto/4109739640f8b21b278ca5060012fbf7)
- [List of jobs per project](https://log.gprd.gitlab.net/goto/63f83c2a163fb0b29edc33b19773db25)

---

## Metrics

- **Metric**: Duration of queuing-related queries for CI runners
- **Unit**: Milliseconds
- **Normal Behavior**: Query duration should remain below the Apdex threshold
- **Threshold Reasoning**: Based on historical performance data and user experience requirements

---

## Alert Behavior

- **Silencing**: Can be silenced temporarily during planned maintenance
- **Expected Frequency**: Medium - may trigger during peak usage periods
- **Historical Trends**: Check [CI Runner alerts dashboard](https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22ci-runners%22%2C%20tier%3D%22sv%22%7D)

---

## Severities

### Impact Assessment

- Affects all GitLab.com users trying to run CI jobs.
- May cause delays in CI/CD pipeline execution.
- Could affect both public and private projects.

### Severity Checks

1. Check number of affected jobs in the queue.
2. Verify impact on pipeline completion times.
3. Monitor error rates in job scheduling.

---

## Verification

- Check [shared runners logs](https://log.gprd.gitlab.net/goto/b9aed2474a7ffe194a10d4445a02893a).
- Review runner manager metrics.
- Monitor database performance metrics.

---

## Troubleshooting

### Basic Steps

1. Check for recent [surge in CI job creation](../service-ci-runners.md#surge-of-scheduled-pipelines).
2. Verify [runner manager health](https://dashboards.gitlab.net/goto/uXCF8OvNg?orgId=).
3. Review [database performance metrics](https://dashboards.gitlab.net/goto/jykuUODNR?orgId=1).
4. Check for [cryptocurrency mining abuse.](../service-ci-runners.md#abuse-of-resources-cryptocurrency-mining)
5. Check if [GitLab.com usage has outgrown it's surge capacity](../service-ci-runners.md#gitlabcom-usage-has-outgrown-its-surge-capacity)

### Additional Checks

- Review scheduled pipeline timing conflicts.
- Verify runner pool capacity.
- Check for stuck jobs.

---

## Possible Resolutions

1. Scale up runner manager capacity.
2. Optimize database queries.
3. Block abusive users/projects.
4. Adjust job scheduling algorithms.

### **Verify for deadtuples-related performance issues**

During reindexing operations, deadtuples may accumulate and degrade query performance.

#### How to Check Ongoing Reindexing Operations

Use the following SQL query to identify reindexing operations causing long query durations:

```sql
SELECT
  now(),
  now() - query_start AS query_age,
  now() - xact_start AS xact_age,
  pid,
  backend_type,
  state,
  client_addr,
  wait_event_type,
  wait_event,
  xact_start,
  query_start,
  state_change,
  query
FROM pg_stat_activity
WHERE
  state != 'idle'
  AND backend_type != 'autovacuum worker'
  AND xact_start < now() - '60 seconds'::interval
ORDER BY xact_age DESC NULLS LAST;
```

### How to Cancel Reindexing and Resume Deadtuple Cleanup

Use the `pg_cancel_backend()` function to cancel the ongoing reindexing operation, using the `pid` from the query above.

```sql
SELECT pg_cancel_backend(1641690);
```

Once canceled, you should see immediate relief in the [gitlab_ci_queue_retrieval_duration_seconds_bucket](https://dashboards.gitlab.net/goto/uHOt_ODHR?orgId=1) metrics

---

## Dependencies

- PostgreSQL database
- Runner manager VMs
- Internal load balancers
- GCP infrastructure

---

## Escalation

### When to Escalate

- Alert persists for >30 minutes.
- Multiple runner shards affected.
- Significant impact on pipeline completion times.

### Support Channels

- `#production` Slack channel
- `#ci-runners` Slack channel

---

## Definitions

- [Alert Definition](https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22ci-runners%22%2C%20tier%3D%22sv%22%7D)
- **Tuning Considerations**: Adjust thresholds based on peak usage patterns and user feedback.

---

## Related Links

- [CI Runner Architecture Documentation](https://about.gitlab.com/handbook/engineering/infrastructure/production-architecture/ci-architecture.html)
- [Runner Abuse Prevention](../service-ci-runners.md)
- [ApdexSLOViolation Documentation](../alerts/ApdexSLOViolation.md)
