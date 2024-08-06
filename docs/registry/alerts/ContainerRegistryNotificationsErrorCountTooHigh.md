# ContainerRegistryNotificationsErrorCountTooHigh

**Table of Contents**

[TOC]

## Overview

- What does this alert mean?
  - There have been more than 5 outgoing webhook notifications that failed to be sent for the last 5 minutes. These include internal errors in the registry.
- What factors can contribute?
  - Similar to [ContainerRegistryNotificationsFailedStatusCode](./ContainerRegistryNotificationsFailedStatusCode.md) with the addition of internal errors
  for notifications that have not left the registry.

- What action is the recipient of this alert expected to take when it fires?
  - Network transient errors should self-heal.
  - [Troubleshooting](../webhook-notifications.md#troubleshooting)

## Services

- [Service Overview](../README.md)
- Team that owns the service: [Container Registry](hhttps://handbook.gitlab.com/handbook/engineering/development/ops/package/container-registry/)

## Metrics

- Metric: `registry_notifications_events_total{exported_type=~"Errors|Failures"}`

> Briefly explain the metric this alert is based on and link to the metrics catalogue. What unit is it measured in? (e.g., CPU usage in percentage, request latency in milliseconds)

- [Dashboard URL](https://dashboards.gitlab.net/d/registry-notifications/registry-webhook-notifications-detail) focusing on the panels `Event delivery error rate` and `Event delivery failure rate`.
- Count of errors and/or failures is 5 or more for over 5 minutes.

> Explain the reasoning behind the chosen threshold value for triggering the alert. Is it based on historical data, best practices, or capacity planning?

- Historical data suggests that the registry does not receive any internal errors.
- Failures can happen some times but not for an extended period of time.

> Describe the expected behavior of the metric under normal conditions. This helps identify situations where the alert might be falsely firing.

- The `Event delivery failure rate` panel should have some low activity.
- Historically, `Event delivery error rate` has had no data meaning we want to see this panel empty.

## Alert Behavior

> Expected frequency of the alert. Is it a high-volume alert or expected to be rare?

- Should be rare.

> Show historical trends of the alert firing e.g  Kibana dashboard

- N/A (new alert)

## Severities

> Guidance for assigning incident severity to this alert

- `s4`

> Who is likely to be impacted by this cause of this alert?

- Customers pushing/pulling images to the container registry.

> Things to check to determine severity

- [Service overview](https://dashboards.gitlab.net/d/registry-main/registry3a-overview?orgId=1)
- Escalate if service is degraded for a prolonged period of time.

## Verification

- [Metric explorer](https://dashboards.gitlab.net/goto/gRrbI-rSR?orgId=1)
- [Registry logs](https://log.gprd.gitlab.net/app/r/s/mUjiG)
- [`registry-main/registry-overview`](https://dashboards.gitlab.net/d/registry-main/registry-overview)
- [`registry-notifications/webhook-notifications-detail`](https://dashboards.gitlab.net/d/registry-notifications/webhook-notifications-detail)
- [`api-main/api-overview`](https://dashboards.gitlab.net/d/api-main/api-overview)
- [`cloudflare-main/cloudflare-overview`](https://dashboards.gitlab.net/d/cloudflare-main/cloudflare-overview)
- [Rails API logs](https://log.gprd.gitlab.net/app/r/s/nxwUF).

## Recent changes

> Recent changes

- [Workloads MRs for "Service::Container Registry"](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests?scope=all&state=opened&label_name[]=Service%3A%3AContainer%20Registry)

> How to properly roll back changes

- Check the changelog in the MR that updated the registry.
- Review MRs included in the related release issue
- If any MR has the label ~cannot-rollback applied, a detailed description should exist in that MR.
- Otherwise, proceed to revert the commit and watch the deployment.
- Review the dashboards and expect the metric to go back to normal.

## Troubleshooting

- Registry [troubleshooting](../webhook-notifications.md#troubleshooting)

## Possible Resolutions

## Dependencies

- Rails API
- Cloudflare/firewall rules

# Escalation

- [g_container_registry](https://gitlab.enterprise.slack.com/archives/CRD4A8HG8)
- [s_package](https://gitlab.enterprise.slack.com/archives/CAGEWDLPQ)

# Definitions

- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)

# Related Links

- [Webhook notifications runbook](../webhook-notifications.md)
- [Related alerts](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/registry/alerts?ref_type=heads).
- [Documentation](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/registry/README.md?ref_type=heads).
