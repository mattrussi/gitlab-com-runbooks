# Cell Provisioning and De-Provisioning

## Prerequisites

- Configure [`ringctl` in your enviornment](https://gitlab.com/gitlab-com/gl-infra/ringctl#preparing-your-environment).
- Make sure you have access to [`cells/tissue`](https://ops.gitlab.net/gitlab-com/gl-infra/cells/tissue/).

## How to Provision a new Cell

[`ringctl`](https://gitlab.com/gitlab-com/gl-infra/ringctl) uses adaptive deployment strategy, i.e it takes reference from the exisiting tenant_model from a target_ring and replace just the necessary fields.

> [!note]
> For most cases you would want to take reference from the `ring 0`.

### Provisioning Steps

1. **Create a new `TENANT_MODEL` from the target ring:**

   ```bash
   ringctl cell provision --dry-run --ring 0 --amp_environment <cellsdev|cellsprod> --cell_id <cell_id>
   ```

  <details>
  <summary> Example Run </sumamry>

  ```bash
  ringctl cell provision --dry-run --ring 0 --amp_environment cellsdev --cell_id 134
  ```

  ```bash
  [DRY-RUN] CreateCommit - action: create - path: rings/cellsdev/-1/c01jpmm6vgv82xqkf9.json
  {
    "$schema": "https://gitlab-com.gitlab.io/gl-infra/gitlab-dedicated/tenant-model-schema/v1.62.0/tenant-model.json",
    "amp_gcp_project_id": "amp-b6f1",
    "audit_logging": false,
    "aws_account_id": "211125640907",
    "backup_region": "eu-west1",
    "byod": {
      "instance": "staging.gitlab.com"
    },
    "cells": {
      "cell_id": 134
    },
    "cloud_provider": "gcp",
    "cloudflare_waf": {
      "enabled": true,
      "migration_stage": "COMPLETE",
      "proxied": "NOT_PROXIED"
    },
    "dns_aws_account_id": "211125640907",
    "external_smtp_parameters": {
      "authentication": "login",
      "domain": "mg.staging.gitlab.com",
      "from": "gitlab@mg.gitlab.com",
      "host": "smtp.mailgun.org",
      "pool": true,
      "port": 2525,
      "reply": "noreply@staging.gitlab.com",
      "starttls": true,
      "tls": false,
      "username": "postmaster@mg.staging.gitlab.com"
    },
    "gcp_oidc_audience": "//iam.googleapis.com/projects/1002415312824/locations/global/workloadIdentityPools/gitlab-pool-oidc-amp-1290/providers/gitlab-jwt-amp-1290",
    "gcp_onboarding_state_region": "us-east1",
    "gcp_project_id": "cell-c01jpmm6vgv82xqkf9",
    "gitlab_version": "17.7.0",
    "instrumentor_version": "v16.620.1",
    "internal_reference": "cell-c01jpmm6vgv82xqkf9",
    "managed_domain": "cell-c01jpmm6vgv82xqkf9.gitlab-cells.dev",
    "perform_qa": true,
    "prerelease_version": "17.10.202503180906-6a387d336a7.c1c3e017782",
    "primary_region": "us-east1",
    "reference_architecture": "ra3k_v3",
    "reference_architecture_overlays": [],
    "sandbox_account": false,
    "service_account_impersonation_members": [],
    "site_regions": [
      "us-east1"
    ],
    "tenant_id": "c01jpmm6vgv82xqkf9",
    "use_gar_for_prerelease_image": true
  }
  ```

  </details>

2. **Create a Merge Request (MR) in [`cells/tissue`](https://ops.gitlab.net/gitlab-com/gl-infra/cells/tissue/):**
   - Use the `TENANT_MODEL` JSON output from the previous command
   - Important: Always place the cell initially in the `quarantine ring` (-1 folder) regardless of the target ring
   - Ensure the filename matches `<tenant_id>.json`

4. **Trigger the Instrumentor Stages for cell provisioning:**

  ```bash
   ./ringctl cell deploy -e <cellsdev|cellsprod> <tenant_id> --only-gitlab-upgrade=false
   ```

  > [!note]
  > This command will output a link to the cell pipeline which you can use to track the deployment progress.
  > The pipeline will run all the Instrumentor stages to create your cell.

  > [!warning]
  > The `prepare` stage might fail on the initial run with an error like:
  > Error when reading or editing KMSKeyRing "projects/cell-c01jp4m0711mwrhb8j/locations/us-east1/keyRings/gld-single-region": googleapi: Error 403: Google Cloud KMS API has not been used in project 9065488916 before or it is disabled. Enable it by visiting <https://console.developers.google.com/apis/api/cloudkms.googleapis.com/overview?project=9065488916> then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry.
  > This is expected as the cell project was just created and Google is still enabling the API.
  > Retry the job after approximately 10 minutes to resolve this issue.

5. **Access your new cell:**
   - Once the pipeline completes successfully, access your cell through the domain specified in the `managed_domain` field of the `TENANT_MODEL`
   - Example: `cell-c01jpmm6vgv82xqkf9.gitlab-cells.dev`

## How to De-Provision a Cell

1. **Ensure the target cell is in the quarantine ring:**
   - If not already there, create an MR to move the cell definition to the `-1` folder (quarantine ring)
   - Get the MR approved and merged

2. **Trigger the tear-down pipeline:**

   ```bash
   ringctl cell deprovision --cell <tenant_id> --ring -1 -e <cellsdev|cellsprod>
   ```

   > [!note]
   > This command will output a link to the cell pipeline which you can use to track the tear-down progress.

3. **Remove the cell definition:**
   - After the tear-down pipeline completes successfully, create an MR to delete the cell definition file from [`cells/tissue`](https://ops.gitlab.net/gitlab-com/gl-infra/cells/tissue/)
   - Get the MR approved and merged
