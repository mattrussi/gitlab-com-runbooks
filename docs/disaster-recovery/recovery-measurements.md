# Measuring Recovery Activities

During the process of testing our recovery processes for Zonal and Regional outages, we want to record timing information.
There are three different timing categories right now:

1. Fleet specific VM recreation time
1. Component specific DR restore process time
1. Total DR restore process time

Common measurements:

- Terraform provision time: The time from an apply of a Terraform plan until the end of the full bootstrap (including any restarts).
- Bootstrap time: The time it takes the bootstrap script to complete successfully during a VM being provisioned.

## Gitaly

### VM Recreation Times

| Date | Terraform Provision Time | Bootstrap Time | Notes |
| ---- | ------------------- | -------------- | ----- |
| 2024-06-20 | XX:XX | XX:XX | N/A |

### Gameday DR Process Time

| Date | Duration | Notes |
| ---- | -------- | ----- |
| 2024-XX-XX | XX:XX | N/A |

## Patroni/PGBouncer

### VM Recreation Times

| Date | Terraform Provision Time | Bootstrap Time | Notes |
| ---- | ------------------- | -------------- | ----- |
| 2024-XX-XX | XX:XX | XX:XX | N/A |

### Gameday DR Process Time

| Date | Duration | Notes |
| ---- | -------- | ----- |
| 2024-XX-XX | XX:XX | N/A |
