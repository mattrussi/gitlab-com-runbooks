# Measuring Recovery Activities

[TOC]

During the process of testing our recovery processes for Zonal and Regional outages, we want to record timing information.
There are three different timing categories right now:

1. Fleet specific VM recreation time
1. Component specific DR restore process time
1. Total DR restore process time

## Common measurements

### VM Provision Time

This is the time from when an apply is performed from an MR to create new VMs until we record a successful bootstrap script completion.
In the bootstrap logs (or console output), look for `Bootstrap finished in X minutes and Y seconds.`
When many VMs are provisioned, we should find the last VM to complete as our measurement.

### Bootstrap Time

During the provisioning process, when a new VM is created, it executes a bootstrap script that may restart the VM.
This measurement might take place over multiple boots.
[This script](https://gitlab.com/gitlab-com/runbooks/-/blob/master/scripts/find-bootstrap-duration.sh?ref_type=heads) can help measure the bootstrap time.
This can be collected for all VMs during a gameday, or a random VM if we are creating many VMs.

## Gameday DR Process Time

The time it takes to execute a DR process. This should include creating MRs, communications, execution, and verification.
This measurement is a rough measurement right now since current process has MRs created in advance of the gameday.
Ideally, this measurement is designed to inform the overall flow and duration of recovery work for planning purposes.

## Gitaly

### VM Recreation Times

| Date | Environment | VM Provision Time | Bootstrap Time | Notes |
| ---- | ----------- | ------------------------ | -------------- | ----- |
| 2024-07-10 | GSTG | 00:18:21 | 00:08:48 | [Change issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18221) |
| 2024-06-20 | GPRD | 00:24:13 | 00:07:11 | Initial test of using OS disk snapshots for restore in GPRD. [Change issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18157) |
| 2024-06-10 | GSTG | 00:14:21 | 00:8:01 | [Game Day change issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18091) |

### Gameday Zonal Outage DR Process Time

| Date | Environment | Duration | Notes |
| ---- | ----------- | -------- | ----- |
| 2024-07-10 | GSTG | 01:15:00 | [Change issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18221) |
| 2024-06-10 | GSTG | 01:20:00 | *Time difference is between the change::in-progress & change::complete labels being set. Doesn't include time to create MRs. |

## Patroni/PGBouncer

### VM Recreation Times

| Date | Environment | VM Provision Time | Bootstrap Time | Notes |
| ---- | ----------- | ------------------------ | -------------- | ----- |
| 2024-08-08 | GSTG | 00:20:49 | 00:10:57 | [GSTG Patroni Gameday](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18358) , [This is calculated from the slowest Patroni node among all the clusters.](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18358#note_2037567888) |
| 2024-08-06 | GPRD | 00:17:41 | 00:11:03 | GPRD Patroni [provisioning test](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18334) with the registry cluster. |
| 2024-04-25 | GSTG | HH:MM:SS | 00:06:00 | Collection of a Patroni bootstrap duration baseline while using OS disk snapshots. Terraform apply duration was not recorded. |
| 2024-04-25 | GSTG | HH:MM:SS | 00:35:00 | Collection of a Patroni bootstrap duration baseline while using a clean Ubuntu image. Terraform apply duration was not recorded. |

### Gameday Zonal Outage DR Process Time

| Date | Environment | Duration | Notes |
| ---- | ----------- | -------- | ----- |
| 2024-08-08 | GSTG | 01:12:SS | For this [Gameday excersize on GSTG](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18358) , attempted to create new patroni nodes in recovery zones , took longer than expected because we hit the snapshot quota|

## HAProxy/Traffic Routing Zonal Outage DR Process Time

### VM Creation Times

| Date | Environment | VM Provision Time | Bootstrap time | Notes |
| ---- | ----------- | -------- | ---- | ----- |
| 2024-08-14 | GSTG | 00:14:40 | 00:13:15 | [Game Day change issue on GSTG](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18356) |

### Gameday Zonal Outage DR Process Time

| Date | Environment | Duration | Notes |
| ---- | ----------- | -------- | ----- |
| 2024-08-14 | GSTG | 00:53:00 | [Game Day change issue on GSTG](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18356) |
