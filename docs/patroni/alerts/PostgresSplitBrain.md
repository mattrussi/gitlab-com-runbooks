# PostgresSplitBrain

**Table of Contents**

[TOC]

## Overview

- This alert, named PostgresSplitBrain, is designed to detect a split-brain scenario in a PostgreSQL cluster managed by Patroni. A split-brain occurs when more than one node in the cluster believes it is the primary (read-write) node, which can lead to data inconsistencies and corruption.
- > What factors can contribute?
- > What parts of the service are effected?
- > What action is the recipient of this alert expected to take when it fires?

## Services

- [Patroni Service](../README.md)
- Team that owns the service: [Production Engineering : Database Reliability](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/data_stores/database-reliability/)

## Metrics

- [Link to the metrics catalogue](https://gitlab.com/gitlab-com/runbooks/-/blob/master/mimir-rules/gitlab-gprd/patroni/patroni.yml#L53)
- This Prometheus expression counts the number of PostgreSQL instances in the gprd/gstg environment that are not in replica mode   `(pg_replication_is_replica == 0)`. If this count is greater than 1, it triggers the alert. This condition indicates that more than one PostgreSQL instance is operating in read-write mode within a cluster.This condition must be true for at least 1 minute to trigger the alert.
- > Describe the expected behavior of the metric under normal conditions. This helps identify situations where the alert might be falsely firing.
- > Add screenshots of what a dashboard will look like when this alert is firing and when it recovers
- > Are there any specific visuals or messages one should look for in the screenshots?

## Alert Behavior

- > Information on silencing the alert (if applicable). When and how can silencing be used? Are there automated silencing rules?
- > Expected frequency of the alert. Is it a high-volume alert or expected to be rare?
- > Show historical trends of the alert firing e.g  Kibana dashboard

## Severities

- > Guidance for assigning incident severity to this alert
- > Who is likely to be impacted by this cause of this alert?
  - > All gitlab.com customers or a subset?
  - > Internal customers only?
- > Things to check to determine severity

## Verification

- > Prometheus link to query that triggered the alert
- > Additional monitoring dashboards
- > Link to log queries if applicable

## Recent changes

- > Links to queries for recent related production change requests
- > Links to queries for recent cookbook or helm MR's
- > How to properly roll back changes

## Troubleshooting

- > Basic troubleshooting order
- > Additional dashboards to check
- > Useful scripts or commands

## Possible Resolutions

- > Links to past incidents where this alert helped identify an issue with clear resolutions

## Dependencies

- > Internal and external dependencies which could potentially cause this alert

# Escalation

- > How and when to escalate
- > Slack channels where help is likely to be found:

# Definitions

- > Link to the definition of this alert for review and tuning
- > Advice or limitations on how we should or shouldn't tune the alert
- [Link to edit this playbook](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/patroni/alerts/PostgresSplitBrain.md?ref_type=heads)
- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)

# Related Links

- [Related alerts](./)
- > Related documentation
