# Privileged Access Management

[[_TOC_]]

## Background

By default, GitLab Team Members have no access to GCP resources created by Runway provisioner. PAM (Privileged Access Management) allows users to temporarily _escalate_ their access by requesting an _entitlement_ for a given duration.

## When to escalate

Refer to [cells breakglass documentation](../cells/breakglass.md) on when to escalate.

## How to escalate

Google provides guides to request access through [the console](https://cloud.google.com/iam/docs/pam-request-temporary-elevated-access#request-grant-console)
and through the [`gcloud` CLI](https://cloud.google.com/iam/docs/pam-request-temporary-elevated-access#request_a_grant_programmatically).

`PROJECT_GROUP` refers to the name set in `gcp_project_groups` field of the [`inventory.yml` of the provisioner project](https://gitlab.com/gitlab-com/gl-infra/platform/runway/provisioner/-/blob/45da3f461533317948bf8aaf1f873f7f87c585f7/inventory.yml#L225). `ENV` is either `stg` for staging or `prod` for production.

Search for valid entitlements with `gcloud`:

```sh
gcloud pam entitlements search \
    --caller-access-type=grant-requester \
    --location=global \
    --project=gitlab-runway-${PROJECT_GROUP}-${ENV}
```

### project_read

This entitlement provides the ability to view resources within a project scope. e.g. view the Cloud Run console for metrics and logs.

This entitlement grants the [default project_read roles](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/library/terraform/google-privileged-access-manager/-/blob/b33519534114f77aabce11c6832c1782bac2eccd/predefined-entitlements.tf#L30) and additional [runway-related roles](https://gitlab.com/gitlab-com/gl-infra/platform/runway/provisioner/-/blob/45da3f461533317948bf8aaf1f873f7f87c585f7/modules/managed_project/locals.tf#L58).

- Get access with `gcloud`:

```sh
gcloud pam grants create \
    --entitlement=readonly-entitlement-gitlab-runway-topo-svc-stg \
    --requested-duration="3600s" \
    --justification="$ISSUE_LINK" \
    --location=global \
    --project=gitlab-runway-${PROJECT_GROUP}-${ENV}
```

### project_admin

Admin access provides typical operational abilities for managing runway infrastructure. This level of access requires an approver, and typically will also link to an issue detailing why the access is required.

We should prefer making changes through IaC wherever possible.

This entitlement grants the [default project_read roles](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/library/terraform/google-privileged-access-manager/-/blob/b33519534114f77aabce11c6832c1782bac2eccd/predefined-entitlements.tf#L55),  additional [runway-related readonly roles](https://gitlab.com/gitlab-com/gl-infra/platform/runway/provisioner/-/blob/45da3f461533317948bf8aaf1f873f7f87c585f7/modules/managed_project/locals.tf#L58) and [runway-related readwrite roles](https://gitlab.com/gitlab-com/gl-infra/platform/runway/provisioner/-/blob/45da3f461533317948bf8aaf1f873f7f87c585f7/modules/managed_project/locals.tf#L80).

- Get access with `gcloud`:

```sh
gcloud pam grants create \
    --entitlement=readwrite-entitlement-gitlab-runway-topo-svc-stg \
    --requested-duration="3600s" \
    --justification="$ISSUE_LINK" \
    --location=global \
    --project=gitlab-runway-${PROJECT_GROUP}-${ENV}
```

### breakglass

Breakglass provides the same level of access as the [`project_admin`](#project_admin) entitlement. This entitlement should only by used as a last resort during an incident response when there is low team member availability to speed up incident response.

- Get access with `gcloud`:

```sh
gcloud pam grants create \
    --entitlement=breakglass-entitlement-gitlab-runway-topo-svc-stg \
    --requested-duration="3600s" \
    --justification="$ISSUE_LINK" \
    --location=global \
    --project=gitlab-runway-${PROJECT_GROUP}-${ENV}
```
