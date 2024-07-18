# HAProxyServerDown

**Table of Contents**

[TOC]

## Overview

This alert indicates that there could be a spike in 5xx errors, server connection errors, or backends reporting unhealthy (backend server is down).

*Note*: [`set-server-state` server draining](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/haproxy.md?ref_type=heads#set-server-state) will also generate this alert.

## Services

- [Service Overview](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/haproxy.md?ref_type=heads)
- Team that owns the service: [Production Engineering Foundations Team](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/systems/gitaly/)
- **Label:** gitlab-com/gl-infra/production~"Service::HAProxy"

## Metrics

- Briefly explain the metric this alert is based on and link to the metrics catalogue. What unit is it measured in? (e.g., CPU usage in percentage, request latency in milliseconds)
- Explain the reasoning behind the chosen threshold value for triggering the alert. Is it based on historical data, best practices, or capacity planning?
- Describe the expected behavior of the metric under normal conditions. This helps identify situations where the alert might be falsely firing.
- Add screenshots of what a dashboard will look like when this alert is firing and when it recovers
- Are there any specific visuals or messages one should look for in the screenshots?

## Alert Behavior

If you drain a node using `set-server-state` tool, [add a new silence](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/haproxy.md?ref_type=heads#set-server-state) before draining.

## Severities

- This alert might create incidents with Severity 3 or 4. Severity 2 incidents are possible, but rare
- There might be customer user impact depending on which service is affected

## Verification

- [Frontend dashboard](https://dashboards.gitlab.net/d/frontend-main/frontend3a-overview?orgId=1)
- [GCP BigQuery HAProxy logs](https://console.cloud.google.com/bigquery?referrer=search&project=gitlab-production&ws=!1m4!1m3!3m2!1sgitlab-production!2shaproxy_logs)
- [HAProxy Logging docs](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/haproxy-logging.md)

## Recent changes

- [Recent HAProxy Production Changes and Incident Issues](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=all&label_name%5B%5D=Service%3A%3AHAProxy&first_page_size=100)
- [Recent Chef HAProxy changes](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/merge_requests?scope=all&state=merged&label_name[]=Service%3A%3AHAProxy)

## Troubleshooting

Errors are being reported by HAProxy, this could be a spike in 5xx errors, server connection errors, or backends reporting unhealthy.

- [HAProxy Troubleshooting](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/haproxy.md?ref_type=heads#haproxy-alert-troubleshooting)
- [HAProxy Logging](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/haproxy-logging.md)
- [Other troubleshooting docs](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/frontend)

## Possible Resolutions

- Links to past incidents where this alert helped identify an issue with clear resolutions:
  - [Previous HAProxy closed incidents](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=closed&label_name%5B%5D=Service%3A%3AHAProxy&label_name%5B%5D=incident&first_page_size=100)
  - [2023-09-25: gprd failind due to haproxy assets are DOWN](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16425)
  - [2023-04-14: Spike in ErrorRatio in HAProxy](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8725)
  - [2023-02-08: Large short-lived burst in haproxy traffic](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8373)

## Dependencies

There are no external dependency for this alert

# Escalation

- Slack channels where help is likely to be found: `#g_infra_foundations`

# Definitions

- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)

# Related Links

- [Related alerts](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/frontend/alerts?ref_type=heads)
- Related documentation
  - [HAProxy Logging](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/haproxy-logging.md?ref_type=heads)
  - [`asset_proxy` is `DOWN`](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/asset-proxy-down.md?ref_type=heads)
  - [IPs and Net Blocking](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/ban-netblocks-on-haproxy.md?ref_type=heads)
  - [Blocking and Disabling Things in HAProxy](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/block-things-in-haproxy.md?ref_type=heads)
  - [`gitlab.com` is down](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/gitlab-com-is-down.md?ref_type=heads)
  - [Increased Error Rate](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/high-error-rate.md?ref_type=heads)
  - [Possible Breach of SSH MaxStartups](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/ssh-maxstartups-breach.md?ref_type=heads)
  - [SSL Certificate Expiring or Expired](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/ssl_cert.md?ref_type=heads)

- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)
