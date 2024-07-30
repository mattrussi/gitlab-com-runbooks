# High Number of Pending or Failed Outgoing Webhook Notifications

**Table of Contents**

[TOC]

## Background

The Container Registry is configured to emit [webhook notifications](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/notifications.md?ref_type=heads)
that are consumed by the GitLab Rails `/api/v4/container_registry_event/events` endpoint as seen in [here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/values.yaml.gotmpl#L206).

These notifications are used by Rails to keep track of registry statistics and usage, thus making this endpoint not critical.
However, the webhook notification system enqueues events one at a time per registry instance, attempting to
send the event until it succeeds, which can lead to problems of high resource consumption as seen in
[this issue](https://gitlab.com/gitlab-org/container-registry/-/issues/1210).

NOTE:
There is pending work to fix the the issue above by replacing the `threshold` setting with `maxretries` (see https://gitlab.com/gitlab-org/container-registry/-/issues/1311).

## Causes

A high number of pending or failed events is likely related to one of these possibilities:

- Networking error while sending an outgoing request to the `/api/v4/container_registry_event/events` endpoint on GitLab.com;
- An application bug in the registry webhook notifications code.

## Symptoms

The [`ContainerRegistryNotificationsPendingCountTooHigh`](../../mimir-rules/gitlab-gprd/registry/registry-notifications.yml) alerts will be triggered if the number of
pending outgoing events count is higher than the configured threshold for a prolonged period of time.

A small API impact could be expected in these situations while [this issue](https://gitlab.com/gitlab-org/container-registry/-/issues/1311) is implemented.
Ideally, we would catch high resource usage by different metrics, as well as the Kubernetes scheduler recycling pods
if the memory/CPU usage threshold is reached.

Also, the `ContainerRegistryNotificationsFailedStatusCode` alerts when the response code received by the registry notifications system is
different than the expected `200 OK`. The metric `registry_notifications_status_total` can be used to help diagnose a potential networking problem.

## Troubleshooting

We first need to identify the cause for the accumulation of pending outgoing notifications. For this, we can look at the following Grafana dashboards:

1. [`registry-main/registry-overview`](https://dashboards.gitlab.net/d/registry-main/registry-overview)
1. [`registry-notifications/webhook-notifications-detail`](https://dashboards.gitlab.net/d/registry-notifications/webhook-notifications-detail)
1. [`api-main/api-overview`](https://dashboards.gitlab.net/d/api-main/api-overview)
1. [`cloudflare-main/cloudflare-overview`](https://dashboards.gitlab.net/d/cloudflare-main/cloudflare-overview)

In (1), we should inspect the current Apdex/error rate SLIs, both for the server (to rule out any unexpected customer impact) and database components.
Expanding the `Node Metrics` section can be used to get an indication of high memory or CPU usage.

In (2), we should look at the failure and error rates, as well as the different status codes in the `Events per second (by Status Code)` panel.

In (3) and (4), we should look for potential errors at the Rails API level or any Cloudflare errors affecting the notifications delivery rate.

In the presence of errors, we should also look at the registry access/application logs in Kibana. This might allow us to see error details while trying to send a notification
by searching for the string `error writing event`.
The same applies to Sentry, where all unknown application errors are reported.

## Resolution

Suppose there are no signs of relevant application/network errors, and all metrics seem to point to an inability to keep up with the demand. In that case, we should likely adjust the [notifications settings](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#notifications) to meet the demand by, for example, increasing the `backoff` period and/or adjusting the `threshold` setting.

An alternative is to recycle the affected pods. However, the events in the pending queue will be dropped, affecting the
Registry Usage metrics.

In the presence of errors, the development team should be involved in debugging the underlying cause.
