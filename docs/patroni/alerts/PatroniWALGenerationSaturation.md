# (Title: Name of alert)

**Table of Contents**

[TOC]

## Overview

This alert means Postgres Write Ahead Log (WAL) Generation is exceeding 150 MB/s (over [5m]) on the primary server of the relevant cluster.

High WAL Generation could be caused by many things; query pattern changes, processes modifying large amounts of data, database maintenance etc. Also this is a saturation metric which we will slowly tip toe up to over time, and without other invention this alert will page more frequently as we run out of headroom.

High WAL Generation is sign of an impending saturation limit with WAL Reciever and/or WAL apply. We theorize that at 150 MB/s (over [5m]) WAL Generation the replicas will not able to recieve and apply the data fast enough to keep up with generation leading to saturation-induced replication lag.

Replication lag means the data on the replicas will be stale compared to the data on the primaries. This could lead to the loadbalancer keeping sticky reads on the primary longer (more load on primary) or if the replication lag gets older than 2 minutes the loadbalancer will redirect all read traffic to primary (even more load on primary). Finally, there could be data loss if an unexpected failover was to occur.

Its also worth noting that on the replicas both CPU and disk IO increases with WAL Generation rate, regardless of the content of that WAL data.

The recipiant should investigate what could have caused the WAL spike, and whether the spike is a early warning sign of an impending saturation limit with WAL Reciever and/or WAL apply.

The recipiant can use this playbook to help [Replication is lagging or has stopped](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/postgres.md#replication-is-lagging-or-has-stopped)

## Services

- [Patroni Service](../README.md)
- Team that owns the service: [Production Engineering : Database Operations](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/data_stores/database-reliability/)


## Metrics

- > Briefly explain the metric this alert is based on and link to the metrics catalogue. What unit is it measured in? (e.g., CPU usage in percentage, request latency in milliseconds)
- > Explain the reasoning behind the chosen threshold value for triggering the alert. Is it based on historical data, best practices, or capacity planning?
- Both [modelling and historical data](https://gitlab.com/gitlab-com/gl-infra/observability/team/-/issues/3653) strongly suggested that a sustained WAL generation rate above 150 MB/s is enough to cause sustained replication lag, even on the c3 machine family
- > Describe the expected behavior of the metric under normal conditions. This helps identify situations where the alert might be falsely firing.
- At the moment under normal capacity a peak spike in WAL Generation is about 140 MB/s and normal behaviour is between 25 MB/s and 125 MB/s
![NormalConditionForPatroniWALGenerationSaturation](image.png)
- > Add screenshots of what a dashboard will look like when this alert is firing and when it recovers
- > Are there any specific visuals or messages one should look for in the screenshots?

## Alert Behavior

- This alert will clear once Postgres Write Ahead Log (WAL) Generation is no longer exceeding 150 MB/s (over [5m]). The alert should not be silenced. Even if this alert triggers and then self resolves it will still be worth the time to figure out what happened and why.
- It is expected that the alert will be currently rare but will become more frequent as we slowly run out of headroom.

## Severities

- This alert is unlikely to be causing active customer issues, and is most likely an S4
- However, this alert could evolve into performance issues for all of GitLab.com
- Check the [Patroni SLI Overview Dashboard](https://dashboards.gitlab.net/d/patroni-main/patroni3a-overview?orgId=1) to determine whether we are already experiencing performance issues

## Verification

- > Prometheus link to query that triggered the alert
- > Additional monitoring dashboards
- > Link to log queries if applicable

## Recent changes

- [Recent Patroni Service change issues](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=updated_desc&state=opened&or%5Blabel_name%5D%5B%5D=Service%3A%3APatroniCI&or%5Blabel_name%5D%5B%5D=Service%3A%3APatroni&or%5Blabel_name%5D%5B%5D=Service%3A%3APatroniRegistry&or%5Blabel_name%5D%5B%5D=Service%3A%3APatroniEmbedding&first_page_size=20)
- [Recent Patroni Change Requests](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=closed&label_name%5B%5D=Service%3A%3APatroni&label_name%5B%5D=change)
- This alert is likely to have been triggered by a recent deployment, rather than a database related change.
- If there is a deployment causing the issue, roll back the change that was deployed
- If a change request caused the problem, follow the rollback instructions in the Change Request.

## Troubleshooting

- [Replication is lagging or has stopped](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/postgres.md#replication-is-lagging-or-has-stopped)

## Possible Resolutions

- This alert has not yet been involved in an incident, however if the alert had been created before 2025 it would have triggered in this incident [Issue 19033](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19033)

## Dependencies

- > Internal and external dependencies which could potentially cause this alert

# Escalation

- If the recipient of this alert cann't determine the cause of the increased WAL Generation and correct it using the troubleshooting steps above, it may be necessary to escalate
- Slack channels where help is likely to be found:
`#g_database_frameworks`
`#g_database_operations`

# Definitions

- > Link to the definition of this alert for review and tuning
- If significant tuning was done on the replicas so that they were able to handle a higher rate of WAL generation then it might be possible to increase 150 MB/s to a higher number.
- [Link to edit this playbook](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/patroni/alerts/PatroniWALGenerationSaturation.md?ref_type=heads)
- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)

# Related Links

- [Related alerts](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/alerts/)
- [Postgres Runbook docs](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/postgres)
- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)
