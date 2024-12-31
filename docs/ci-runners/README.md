<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# CI Runners Service

* [Service Overview](https://dashboards.gitlab.net/d/ci-runners-main/ci-runners-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22ci-runners%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::CI Runners"

## Logging

* [shared runners](https://log.gprd.gitlab.net/goto/b9aed2474a7ffe194a10d4445a02893a)

## Troubleshooting Pointers

* [ApdexSLOViolation](../alerts/ApdexSLOViolation.md)
* [ci-apdex-violating-slo.md](ci-apdex-violating-slo.md)
* [service-ci-runners.md](service-ci-runners.md)
* [Zonal and Regional Recovery Guide](../disaster-recovery/recovery.md)
* [Rails SQL Apdex alerts](../patroni/rails-sql-apdex-slow.md)
<!-- END_MARKER -->

---

## 1. CI Runner Overview

### 1.1 What are CI Runners?

CI Runners are the backbone of GitLab's CI/CD workflows. They are specialized components responsible for executing the tasks and jobs defined in the `.gitlab-ci.yml` configuration file. Runners interact with GitLab’s API to receive jobs and run them in isolated environments, ensuring clean states for every pipeline execution.

#### Key Responsibilities

1. **Job Execution**: Execute scripts, commands, and test suites provided in the CI/CD configuration.
2. **Resource Isolation**: Maintain isolated environments to ensure jobs do not interfere with each other.
3. **Environment Management**: Set up required dependencies, containers, or virtual machines dynamically.
4. **Scalability**: Scale infrastructure dynamically based on job load.
5. **Artifact Management**: Handle the storage and transfer of job artifacts between pipeline stages.
6. **Cache Management**: Manage caching mechanisms to speed up subsequent pipeline runs.
7. **Security Scanning**: Execute security scans and vulnerability checks as part of the pipeline.

#### Why CI Runners Matter

* **Reliability**: Each job runs in a clean, reproducible environment, reducing flakiness.
* **Automation**: Automates testing, deployment, and integration processes.
* **Scalability**: Accommodates thousands of jobs simultaneously through autoscaling.
* **Flexibility**: Supports different environments, platforms, and architectures (Linux, Windows, macOS).
* **Cost Efficiency**: Optimizes resource usage by spinning up environments only when needed.
* **Compliance**: Helps maintain compliance requirements through consistent, tracked execution environments.
* **Debug Capability**: Provides detailed logs and execution traces for troubleshooting.

---

### 1.2 Runner Types

GitLab supports two main categories of CI Runners:

#### 1. **Internal Runners**

These runners are used exclusively for GitLab-managed projects. They operate within dedicated infrastructure, ensuring higher performance, reliability, and security. Examples include:

* **Private shard (PRM - Private Runners Manager)**: Dedicated to internal teams and private instances.
* **gitlab-org shard (GSRM - GitLab Shared Runners Manager)**: Dedicated for projects managed under `gitlab-org` namespace.
* **macos-staging shard**: Specialized runners for macOS jobs on staging environments.

#### 2. **External Runners**

These runners are shared or self-managed by external users of GitLab.com. External runners are typically:

* **Shared runners (SRM - Shared Runners Manager)**: Provided by GitLab as a service for all public and private repositories.
* **gitlab-docker-shared-runners (GDSRM - GitLab Docker Shared Runners Manager)**: Manages the docker runners
* **windows-runners (WSRM - Windows Shared Runners Manager)**: Handles the windows runners

**Comparison of Internal vs. External Runners:**

| Feature               | Internal Runners                         | External Runners                 |
| ----------------------| ---------------------------------------- | -------------------------------- |
| **Infrastructure**    | Managed by GitLab                       | Self-hosted or GitLab-managed    |
| **Access**            | Restricted to GitLab projects           | Available to all users           |
| **Performance**       | Optimized for GitLab workflows          | Dependent on host environment    |
| **Security**          | Enhanced isolation & dedicated resources| Varies based on implementation   |

---

#### Runner Workflow

The workflow of a CI Runner involves multiple steps:

1. **Pre-job Checks**:
   * Verify runner capabilities match job requirements
   * Ensure required resources are available

2. **Job Retrieval**: Runners fetch job details from the GitLab API.

3. **Cache Restoration**:
   * Restore cached dependencies
   * Download artifacts from previous stages

4. **Environment Setup**: Prepare the required execution environment (e.g., Docker containers or VMs).

5. **Job Execution**: Run the scripts, commands, or pipelines as specified.

6. **Health Checking**:
   * Regular status reporting to GitLab
   * Monitor resource usage and job progress

7. **Job Reporting**: Send job status, logs, and artifacts back to GitLab.

8. **Cleanup**: Terminate or clean up the environment to ensure isolation.

---

### 1.3 High-Level Runner Architecture

Below is a description of the runner components and their relationships:

#### Components of the Runner System

1. **Runner Managers**:
   * Purpose: Coordinate the retrieval and execution of jobs.
   * Functionality: Manage scaling, orchestration, and job lifecycle.
   * GitLab.com specifically has several types:
     * shared-runners-manager (srm)
     * gitlab-shared-runners-manager (gsrm)
     * gitlab-docker-shared-runners-manager (gdsrm)
     * private-runners-manager (prm)

2. **Load Balancers**:
   * Purpose: Distribute job load across multiple runner managers.
   * Implementation: CI runners use Internal Load Balancers (ILBs) called "ci-gateway" to reduce traffic costs and improve performance. There are ILBs in both GSTG (staging) and GPRD (production) environments and each environment has ILBs across different availability zones (us-east1-b, us-east1-c, us-east1-d). The ILBs connect to HaProxy nodes that have interfaces in both the main VPC and ci-gateway VPC and the load balancers are accessible through specific internal FQDNs like:
      * git-us-east1-c.ci-gateway.int.gprd.gitlab.net
      * git-us-east1-d.ci-gateway.int.gprd.gitlab.net
      * git-us-east1-c.ci-gateway.int.gstg.gitlab.net
      * git-us-east1-d.ci-gateway.int.gstg.gitlab.net
   The setup helps optimize costs by keeping traffic within GCP's internal network when possible, only routing to the public internet when necessary (like for artifact uploads/downloads).

3. **Compute Resources**:
   * Virtual Machines or containers provisioned dynamically for job execution.
   * Categories: Shared VM pools, private pools, macOS pools, and Windows pools.
   * Specific resource tiers (S, M, L, XL, 2XL)

4. **Monitoring Stack**:
   * Components: Prometheus, Grafana, and Mirmir.
   * Functionality: Monitor job performance, health, and resource usage.

5. **Network Components**:
   * Purpose: Handle secure communication between runners and GitLab
   * Implementation: Shared VPC architecture, Strict firewall rules and network policies
   * Security: Manage access controls and network isolation

---

## SSH

To ssh into any VM under the `gitlab-ci-155816` GCP project which hosts the runner-manager VMs, add the following to your `.config/ssh` file:

```
# ci-runner manager VMs
Host *.gitlab-ci-155816.internal
        ProxyJump   lb-bastion.ci.gitlab.com
```

### External Runners

See [Hosted runners for -com](https://docs.gitlab.com/ee/ci/runners/index.html#hosted-runners-for-gitlabcom).

## Runner Deployments

### blue-green-deployment

Each of the gitlab.com SaaS runners shards have two running clusters, consisting of a set of runner-manager VMs available at all time, we refer to them as blue and green. This is meant to speed up the release of [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner) by shifting traffic
between two identical environments that are running different versions of the application. For further info please see the [blue-green README](./release-cycle/blue_green_deployment.md).

Currently the deployment supports the following architectures:

1. [Linux Architecture](./linux/README.md)
1. [Mac Architecture](./macos/README.md)

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

## Monitoring

![CI Runners monitoring stack design](./img/ci-runners-monitoring.png)

Monitoring is be defined in almost the same configuration in all CI related projects. It is deployed using GKE and
a cluster created by terraform. For that
[a dedicated terraform module](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/tree/master/modules/ci-runners/gke)
was created. For it's purpose the GKE cluster is using the `runners-gke` network defined above.

Prometheus is deployed in at least two replicas. Both have a Thanos Sidecar running alongside. Sidecar's gRPC
endpoint is exposed as publicly accessible (we don't want to peer the `ops` or `gprd` network here) and the GCP Firewall
limits access to it to only Thanos Query public IPs. This service uses TCP port `10901`.

Long-term metrics storage is handled by using a dedicated GCS bucket created by the terraform module alongside
the cluster. Thanos Sidecar is configured with write access to this bucket.

Apart from the Sidecar we also have Thanos Store Gateway and Thanos Compact deployed and configured to use the same
GCS bucket. Store Gateway's gRPC endpoint is exposed similarly to the Sidecar's one. This service uses TCP port `10903`.

[Traefik](https://traefik.io/) is used as the ingress and load-balancing mechanism. It exposes gRPC services on given
ports (using TCP routing), Prometheus UI and own dashboard. HTTP endpoints are automatically redirected to HTTPS,
and Let's Encrypt certificates are used for TLS.

For external access each project where monitoring is deployed is using a reserved public IP address. This address
is bound to two DNS A records:

* `monitoring-lb.[ENVIRONMENT].ci-runners.gitlab.net` - which is used for Thanos Query store DNS discovery and
  to access Traefik dashboard in the browser. Access to the Dashboard is limited by oAuth, using Google as the Identity
  Provider allowing `@gitlab.com` accounts. Consent screen and oAuth2 secrets are defined in the `gitlab-ci-155816`
  project and should be used for all deployments of this monitoring stack (**remember:** new deploys will use new
  domains for the redirection URLs, which should be added to the oAuth2 credentials configuration; unfortunately this
  can't be managed by terraform).
* `prometheus.[ENVIRONMENT].ci-runners.gitlab.net` - which is used to access directly the Prometheus deployment. As with
  the Traefik dashboard, access is limited by oAuth2 with the same configuration.

K8S deployment configuration is managed fully from CI. [A dedicated
project](https://gitlab.com/gitlab-com/gl-infra/ci-runners/k8s-workloads) covers all monitoring clusters in different
CI projects that we maintain.

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
