# ComponentResourceRunningOut_disk_space

**Table of Contents**

[TOC]

## Overview

This alert means that the disk space utilization on a disk for a node is growing rapidly and will reach it's capacity in the next 6 hours. The cause of the fast growth should be investigated.

Affected Service will be mentioned in the alert and the team owning the service can be determined in the [Service Catalog](https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.yml?ref_type=heads) by searching for the Service name.

## Services

This alert does not have an assigned team and created from [the template](https://gitlab.com/gitlab-com/runbooks/-/blob/master/libsonnet/servicemetrics/resource_saturation_point.libsonnet?ref_type=heads#L208). So the alert can be firing for any GitLab component. To identify the team, identify the service for which the alert fired and search through the [Service Catalog](https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.yml?ref_type=heads) to get the details about the ownership.

## Metrics

The [alert expression](https://gitlab.com/gitlab-com/runbooks/-/blob/master/libsonnet/servicemetrics/resource_saturation_point.libsonnet?ref_type=heads#L209) is predicting whether the component saturation will exceed the defined hard SLO within the specified time frame. This means that this resource is growing rapidly and is predicted to exceed saturation threshold within the specified interval.

## Alert Behavior

This alert is rare and if triggered, should be investigated, as it may lead to the fullfilment of the available disk space on a node, which could trigger other incidents with higher Severity. It is not recommended to silence this alert.

## Severities

This alert is usually assigned a low Severity (S4 or S3)

## Verification

- > Prometheus link to query that triggered the alert
- > Additional monitoring dashboards
- > Link to log queries if applicable

## Recent changes

The alert is applicable to many services, and created from a template. To find out recent changes review the [closed prodcution issues for a specific Service](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=all&first_page_size=100). To filter the issue to the affected service from the alert apply search filter with `Label=Service::<service_name>`. [Example for HAProxy service](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=all&label_name%5B%5D=Service%3A%3AHAProxy&label_name%5B%5D=change&first_page_size=100)

## Troubleshooting

Basic troubleshooting will require a direct access to the affected nodes/services and investigation of the disk usage and capacity using `sudo du -sh` tool. This may help to identify the source of the disk usage growth. 

## Possible Resolutions

Examples of the previous incidents:

- [Low disk space on Gitaly storage](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17000)
- [Disk Space Utilization for ci-runners service](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17848)
- [All past incdents for ComponentResourceRunningOut_disk_space alert](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=closed&label_name%5B%5D=a%3AComponentResourceRunningOut_disk_space&first_page_size=100)

## Dependencies

There are no external dependencies for this alert

# Escalation

After the ownership team has been identified for the affected component, search for the Slack channel of the team and look for the escalation there.

Alternative slack channels:

- `[#production_engineering](https://gitlab.enterprise.slack.com/archives/C03QC5KNW5N)`
- `[#infrastructure-lounge](https://gitlab.enterprise.slack.com/archives/CB3LSMEJV)`

# Definitions

- [ComponentResourceRunningOut_ alert definition](https://gitlab.com/gitlab-com/runbooks/-/blob/master/libsonnet/servicemetrics/resource_saturation_point.libsonnet?ref_type=heads#L208)
- [Edit this playbook](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/config_management/alerts/ComponentResourceRunningOut_disk_space.md)
- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)

# Related Links

- [Related alerts](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/config_management/alerts/ComponentResourceRunningOut_disk_space.md)
- [Alert template](https://gitlab.com/gitlab-com/runbooks/-/blob/master/libsonnet/servicemetrics/resource_saturation_point.libsonnet?ref_type=heads#L208)
- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)