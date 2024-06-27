# Measuring Recovery Activities

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

| Date | Environment | Terraform Provision Time | Bootstrap Time | Notes |
| ---- | ----------- | ------------------------ | -------------- | ----- |
| 2024-06-20 | GPRD | XX:XX | XX:XX | N/A |

### Gameday Zonal Outage DR Process Time

| Date | Environment | Duration | Notes |
| ---- | ----------- | -------- | ----- |
| 2024-XX-XX | GSTG | XX:XX | N/A |

## Patroni/PGBouncer

### VM Recreation Times

| Date | Environment | Terraform Provision Time | Bootstrap Time | Notes |
| ---- | ----------- | ------------------------ | -------------- | ----- |
| 2024-06-20 | GPRD | XX:XX | XX:XX | N/A |

### Gameday Zonal Outage DR Process Time

| Date | Environment | Duration | Notes |
| ---- | ----------- | -------- | ----- |
| 2024-XX-XX | GSTG | XX:XX | N/A |
