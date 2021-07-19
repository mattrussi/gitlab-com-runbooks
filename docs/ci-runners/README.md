<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

#  Ci-runners Service
* [Service Overview](https://dashboards.gitlab.net/d/ci-runners-main/ci-runners-overview)
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22ci-runners%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:CI Runner"

## Logging

* [shared runners](https://log.gprd.gitlab.net/goto/b9aed2474a7ffe194a10d4445a02893a)

## Troubleshooting Pointers

* [ci-apdex-violating-slo.md](ci-apdex-violating-slo.md)
* [service-ci-runners.md](service-ci-runners.md)
* [../patroni/rails-sql-apdex-slow.md](../patroni/rails-sql-apdex-slow.md)
* [../uncategorized/alert-routing.md](../uncategorized/alert-routing.md)
<!-- END_MARKER -->

# CI Runner Overview

We have several different kind of runners. Below is a brief overview of each.
They all have acronyms as well, which are indicated next to each name.

- [Logging](#logging)
- [Troubleshooting Pointers](#troubleshooting-pointers)
- [Configuration management for the Linux based Runners fleet](linux/README.md)
- [Runner Descriptions](#runner-descriptions)
  - [shared-runners-manager (SRM)](#shared-runners-manager-srm)
  - [gitlab-shared-runners-manager (GSRM)](#gitlab-shared-runners-manager-gsrm)
  - [private-runners-manager (PRM)](#private-runners-manager-prm)
  - [gitlab-docker-shared-runners-manager (GDSRM)](#gitlab-docker-shared-runners-manager-gdsrm)
  - [windows-shared-runners-manager (WSRM)](#windows-shared-runners-manager-wsrm)
- [Cost Factors](#cost-factors)
- [Network Info](#network-info)
  - [gitlab-ci project](#gitlab-ci-project)
  - [gitlab-org-ci project](#gitlab-org-ci-project)
  - [gitlab-ci-windows project](#gitlab-ci-windows-project)
  - [gitlab-ci-plan-free-X projects](#gitlab-ci-plan-free-x-projects)
- [Production Change Lock (PCL)](#production-change-lock-pcl)

## Runner Descriptions

### shared-runners-manager (SRM)

These are the main runners our customers use. They are housed in the `gitlab-ci` project.
Each machine is used for one build and then rebuilt. See [`gitlab-ci` network](#gitlab-ci-project)
for subnet information.

### gitlab-shared-runners-manager (GSRM)

These runners are used for GitLab application tests. They can be used by customer forks of the
GitLab application. These are also housed in the `gitlab-ci` project. See [`gitlab-ci` network](#gitlab-ci-project)
for subnet information.

### private-runners-manager (PRM)

These runners are added to the `gitlab-com` and `gitlab-org` groups for internal GitLab use
only. They are also added to the ops instance as shared runners for the same purpose. They
have privileged mode on. See [`gitlab-ci` network](#gitlab-ci-project) for subnet information.

### gitlab-docker-shared-runners-manager (GDSRM)

These are the newest runners we have. They are used for all of our open source projects under
the `gitlab-org` group. They are also referred to as `org-ci` runners. These are housed in the
`gitlab-org-ci` project. For further info please see the [org-ci README](./cicd/org-ci/README.md).
For network information see [gitlab-org-ci networking](#gitlab-org-ci-project).

### windows-shared-runners-manager (WSRM)

As the name suggests, these are runners that spawn Windows machines. They are currently in
beta. They are housed in the `gitlab-ci-windows` project. For further info please see the
[windows CI README](./cicd/windows/README.md). For network information see [gitlab-ci-windows networking](#gitlab-ci-windows-project).

## Cost Factors

Each runner has an associated `cost factor` that determines how many minutes are deducted from the customers account
per minute used. For example, if a cost factor was 2.0, the customer would use 2 minutes for each minute a CI job
runs. Below is a table that details the cost factor for each runner type.

| Runner Type                                 | Public Project Factor | Private Project Factor |
| ------------------------------------------- | --------------------- | ---------------------- |
| shared-runners-manager (srm)                | 0.0                   | 1.0                    |
| gitlab-shared-runners-manager (gsrm)        | 0.0                   | 1.0                    |
| windows-runners-manager (wsrm)              | 0.0                   | 1.0                    |
| gitlab-docker-shared-runners-manager (gsrm) | 0.0                   | 1.0                    |

## Network Info

Below is the networking information for each project.

### gitlab-ci project

These subnets are created under the `default` network.

| Subnet Name               | CIDR          | Purpose                                                |
|---------------------------|---------------|--------------------------------------------------------|
| default                   | 10.142.0.0/20 | all non-runner machines (managers, prometheus, etc.)   |
| shared-runners            | 10.0.32.0/20  | shared runner (SRM) machines                           |
| private-runners           | 10.0.0.0/20   | private runner (PRM) machines                          |
| gitlab-shared-runners     | 10.0.16.0/20  | gitlab shared runner (GSRM) machines                   |
| ephemeral-runners-private | 10.10.40.0/21 | Ephemeral runner machines for the new `private` shard. |

### gitlab-org-ci project

These subnets are created under the `org-ci` network.

| Subnet Name             | CIDR        | Purpose                               |
| ----------------------- | ----------- | ------------------------------------- |
| manager                 | 10.1.0.0/24 | Runner manager machines               |
| bastion                 | 10.1.2.0/24 | bastion network                       |
| gitlab-gke              | 10.1.3.0/24 | GKE network                           |
| gitlab-gke-pod-cidr     | 10.1.4.0/22 | GKE network used for pod IPs          |
| gitlab-gke-service-cidr | 10.1.8.0/24 | GKE network used for exposed services |
| shared-runner           | 10.2.0.0/16 | Ephemeral runner machines             |

### gitlab-ci-windows project

These subnets are created under the `windows-ci` network.

| Subnet Name        | CIDR        | Purpose                           |
| ------------------ | ----------- | --------------------------------- |
| manager-subnet     | 10.1.0.0/16 | Runner manager machines           |
| executor-subnet    | 10.2.0.0/16 | Ephemeral runner machines         |
| bastion-windows-ci | 10.3.1.0/24 | bastion network                   |
| runner-windows-ci  | 10.3.0.0/24 | Runner network for ansible/packer |

### gitlab-ci-plan-free-X projects

These subnets are created under the `ephemeral-runners` network.

| GCP project             | Subnet Name       | CIDR          | Purpose                   |
| ----------------------- | ----------------- | ------------- | ------------------------- |
| `gitlab-ci-plan-free-3` | ephemeral-runners | 10.10.32.0/21 | Ephemeral runner machines |
| `gitlab-ci-plan-free-4` | ephemeral-runners | 10.10.24.0/21 | Ephemeral runner machines |
| `gitlab-ci-plan-free-5` | ephemeral-runners | 10.10.16.0/21 | Ephemeral runner machines |
| `gitlab-ci-plan-free-6` | ephemeral-runners | 10.10.8.0/21  | Ephemeral runner machines |
| `gitlab-ci-plan-free-7` | ephemeral-runners | 10.10.0.0/21  | Ephemeral runner machines |

## Production Change Lock (PCL)

It is a good practice to temporarily halt production changes during
certain events such as GitLab Summit, major global holidays, and
Weekends. Apart from the list already documented in
<https://about.gitlab.com/handbook/engineering/infrastructure/change-management/#production-change-lock-pcl>,
GitLab Runner extends this with the following:

| Dates                          | Type | Reason  |
| ------------------------------ | ---- | ------- |
| Recurring: Friday              | Soft | Friday  |
| Recurring: Weekend (Sat - Sun) | Soft | Weekend |

<!-- ## Summary -->

<!-- ## Architecture -->

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
