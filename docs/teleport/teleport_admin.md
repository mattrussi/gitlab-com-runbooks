# Teleport Administration

This run book covers administration of the Teleport service from an infrastructure perspective.

- See the [Teleport Rails Console](Connect_to_Rails_Console_via_Teleport.md) runbook if you'd like to log in to a machine using teleport
- See the [Teleport Database Console](Connect_to_Database_Console_via_Teleport.md) runbook if you'd like to connect to a database using teleport
- See the [Teleport Approval Workflow](teleport_approval_workflow.md) runbook if you'd like to review and approve access requests

## Access Changes

Access is configured at:

- Staging [teleport-staging in `config-mgmt`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/teleport-staging)
- Production [teleport-production in `config-mgmt`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/teleport-staging)

Associations between Okta groups and Teleport roles are fairly straightforward, and can be edited in the [groups.tf](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/environments/teleport-production/groups.tf) file.

Modifications to role permissions and settings are made in the `roles-*.tf` files.

## Checking status of the Teleport Server

Teleport runs in two GKE clusters, both in the `gitlab-ops` GCP project:

- `https://staging.teleport.gitlab.net/` in GKE cluster `ops-gitlab-gke` (us-east1)
- `https://production.teleport.gitlab.net/` in GKE cluster `ops-central` (us-central1)

The service in Kubernetes is composed of 2 Deployments (`auth` and `proxy`) that are stateless, all data (certificates, DB, sessions, etc) is stored in external GCP resources (KMS, Firestore, GCS) that reside in their own isolated GCP projects (`gitlab-teleport-*`).

1. Connect to the GKE cluster
2. Check Deployments in the namespace `teleport-cluster-<env>`
3. Get a console into one of the `auth` pods, `teleport` container
4. Execute `tctl status`

This will print the version and some CA info, meaning the cluster is funcioning.

```shell
root@teleport-staging-auth-75b8dc9696-rc856:/# tctl status
Cluster      staging.teleport.gitlab.net
Version      12.2.5
host CA      never updated
user CA      never updated
db CA        never updated
openssh CA   never updated
jwt CA       never updated
saml_idp CA  never updated
CA pin       sha256:<sha>
```

Generally, if the pods are healthy, then the service is healthy.

## Secrets

All cluster cert secrets are stored in KMS, we don't manage any private keys (including CA).

## Slack integration

The slack integration connects to the authentication proxy as a user, using client identity auth.  This client identity does not yet auto-renew.

Follow the Teleport documentation for [generating a new identity](https://goteleport.com/docs/access-controls/access-request-plugins/ssh-approval-slack/#export-the-access-plugin-certificate).
