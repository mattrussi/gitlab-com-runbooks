# ComponentResourceRunningOut_disk_space

**Table of Contents**

[TOC]

## Overview

This alert means that the disk space utilization on a disk for a node is growing rapidly and will reach it's capacity in the next 6 hours. The cause of the fast growth should be investigated.

Affected Service will be mentioned in the alert and the team owning the service can be determined in the [Service Catalog](https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.yml?ref_type=heads) by searching for the Service name.

## Services

This alert does not have an assigned team and created from [the template](https://gitlab.com/gitlab-com/runbooks/-/blob/master/libsonnet/servicemetrics/resource_saturation_point.libsonnet?ref_type=heads#L208). So the alert can be firing for any GitLab component. To identify the team, identify the service for which the alert fired and search through the [Service Catalog](https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.yml?ref_type=heads) to get the details about the ownership.

## Metrics

- > Briefly explain the metric this alert is based on and link to the metrics catalogue. What unit is it measured in? (e.g., CPU usage in percentage, request latency in milliseconds)
- > Explain the reasoning behind the chosen threshold value for triggering the alert. Is it based on historical data, best practices, or capacity planning?
- > Describe the expected behavior of the metric under normal conditions. This helps identify situations where the alert might be falsely firing.
- > Add screenshots of what a dashboard will look like when this alert is firing and when it recovers
- > Are there any specific visuals or messages one should look for in the screenshots?

## Alert Behavior

This alert is rare and if triggered, should be investigated, as it may lead to the fullfilment of the available disk space on a node, which could trigger other incidents with higher Severity. It is not recommended to silence this alert.

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

The alert is applicable to many services, and created from a template. To find out recent changes review the [closed prodcution issues for a specific Service](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=all&first_page_size=100). To filter the issue to the affected service from the alert apply search filter with `Label=Service::<service_name>`. [Example for HAProxy service](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=all&label_name%5B%5D=Service%3A%3AHAProxy&label_name%5B%5D=change&first_page_size=100)

## Troubleshooting

- > Basic troubleshooting order
- > Additional dashboards to check
- > Useful scripts or commands

## Possible Resolutions

Examples of the previous incidents:
- [Low disk space on Gitaly storage](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17000)
- [Disk Space Utilization for ci-runners service](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17848)
- [All past incdents for ComponentResourceRunningOut_disk_space alert](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=closed&label_name%5B%5D=a%3AComponentResourceRunningOut_disk_space&first_page_size=100)

## Dependencies

There are no external dependencies for this alert

# Escalation

- > How and when to escalate
- > Slack channels where help is likely to be found:

# Definitions

- [ComponentResourceRunningOut_ alert definition](https://gitlab.com/gitlab-com/runbooks/-/blob/master/libsonnet/servicemetrics/resource_saturation_point.libsonnet?ref_type=heads#L208)
- [Edit this playbook](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/config_management/alerts/ComponentResourceRunningOut_disk_space.md)
- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)

# Related Links

- [Related alerts](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/config_management/alerts/ComponentResourceRunningOut_disk_space.md)
- [Alert template](https://gitlab.com/gitlab-com/runbooks/-/blob/master/libsonnet/servicemetrics/resource_saturation_point.libsonnet?ref_type=heads#L208)
- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)