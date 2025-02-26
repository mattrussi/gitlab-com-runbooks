# Cells and AMP Documentation

[[_TOC_]]

## Overview

This document describes the relationship between Cells and AMP (a component of GitLab Dedicated tooling), explaining how AMP serves as the control plane for managing Dedicated Tenants, with each Cell representing a Dedicated Tenant.

## AMP Architecture

### Purpose and Functionality

[AMP](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/) (part of `dedicated tooling`) provides a control plane for managing `Dedicated Tenants`. Each Cell is implemented as a `Dedicated Tenant` within this architecture.

AMP orchestrates the provisioning and lifecycle management of Cells through Kubernetes clusters, using the [`Instrumentor`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/instrumentor) service to handle the actual Cell deployments.

### Secret Management

AMP manages the lifecycle of environment-wide secrets, including but not limited to:

- SMTP Configuration
- KAS_AGENT_CONNECT_TOKEN
- INSTRUMENTOR_REGISTRY_TOKEN

These secrets are created via Terraform and passed through `GitLab CI/CD variables` for the target environment. For example, the `TF_SECRETS_VAR_FILE` variable contains necessary Terraform secrets restricted to the `cellsdev` environment.

### Service Account Configuration

AMP configures all required `service-accounts` in GCP and establishes the necessary:

- IAM roles
- OIDC authentication
- Kubernetes cluster configuration

For detailed information about GitLab Dedicated architecture and tooling, refer to the [`architecture`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/tree/main/architecture) and [`engineering`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/tree/main/engineering) documentation.

## Environments

We maintain two distinct AMP environments for Cells management:

### Development Environment (cellsdev)

- **Kubernetes Cluster**: Located in the [`amp-b6f1`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/-/blob/84b37222dcafcceebf271f32ea7f765734a2c7bc/environments/cellsdev/common.hcl#L21) GCP project
- **GCP Organization**: [`gitlab-cells.dev`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/-/blob/84b37222dcafcceebf271f32ea7f765734a2c7bc/environments/cellsdev/common.hcl#L22)
- **Configuration Path**: [environments/cellsdev](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/-/tree/main/environments/cellsdev?ref_type=heads) in the AMP repository

### Production Environment (cellsprod)

- **Kubernetes Cluster**: Located in the [`amp-3cod`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/-/blob/84b37222dcafcceebf271f32ea7f765734a2c7bc/environments/cellsprod/common.hcl#L21) GCP project
- **GCP Organization**: [`gitlab-cells.com`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/-/blob/84b37222dcafcceebf271f32ea7f765734a2c7bc/environments/cellsprod/common.hcl#L22)
- **Configuration Path**: [environments/cellsprod](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/-/tree/main/environments/cellsprod?ref_type=heads) in the AMP repository

Both environments are managed within the [`AMP repository`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp).

## Environment Management

### Bootstrap Process

All AMP environments, including the Cells environments, are bootstrapped via GitLab CI pipelines. The process initializes the necessary infrastructure and configures the Kubernetes clusters that will host the AMP control plane.

Please refer to [AMP Environment Bootstrap](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/#amp-environment-bootstrap) to know more about the complete bootstrapping process.

### Terraform State

Each environment maintains its own Terraform state stored in GitLab Terraform State storage. The state files are managed at [https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/-/terraform](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/-/terraform). This ensures proper separation between environments and prevents cross-environment changes.

### Secret Variables

Sensitive variables (`TF_VAR_*`) are stored as GitLab CI/CD variables scoped to the target environment to maintain proper access control and separation.

## Cell Deployment

### CI/CD Integration

The deployment of Cells leverages the AMP Kubernetes clusters through the [`cells/tissue`](https://ops.gitlab.net/gitlab-com/gl-infra/cells/tissue) CI/CD pipelines.

### KAS Agents

Cell deployments use [KAS agents](https://docs.gitlab.com/user/clusters/agent/) to trigger the deployment process. The KAS secrets are stored in the CI/CD variables of the AMP project, ensuring secure communication between the CI pipelines and the Kubernetes clusters.

## Operational Considerations

### Scaling AMP Clusters

Since the AMP clusters run QA jobs for all cells, they occasionally encounter scaling limitations. Common solutions include:

- Increasing the number of nodes in the cluster
- Provisioning larger node types

For an example of cluster scaling, see [this merge request](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/-/merge_requests/1607).

### Access Management

Access to the Cells environments is managed through [PAM entitlements](https://cloud.google.com/iam/docs/pam-overview), which allow for controlled escalation of privileges to the `cellsdev` or `cellsprod` GCP organizations.

> **Note:** Team members must be connected to NordLayer VPN to access the AMP Kubernetes clusters. For setup and usage instructions, refer to the [NordLayer guide](https://internal.gitlab.com/handbook/it/it-self-service/it-guides/nordlayer/).

### Breakglass Procedures

For emergency access to the Cell/AMP projects or organizations, refer to the [Breakglass](./breakglass.md) documentation, which outlines when and how to properly access these resources.

## Additional Resources

For more information about GitLab Dedicated and related tooling, refer to:

- [GitLab Dedicated Architecture Documentation](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/tree/main/architecture)
- [GitLab Dedicated Engineering Documentation](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/tree/main/engineering)
- [AMP Repository](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/amp/)
- [Instrumentor Repository](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/instrumentor)
