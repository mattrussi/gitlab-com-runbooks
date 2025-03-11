
# Cell Infrastucture Debugging and Development

> [!note]
> For incidents you should look at using [the breakglass guide instead](./breakglass.md).

[[_TOC_]]

## Overview

The Cells Infrastructure Debugging and Development process provides a
way to access specific cell environments through [`cells/tissue`] for
testing and debugging without going through the full build and CI
process.  This is particularly useful for iterative development of
[Instrumentor] changes and manual interventions when an upgrade has
failed.

```mermaid
---
title: When to use Cell Instrumentor Debug Environment
---
flowchart TD
    start[Need to test/debug in a cell environment]

    is_sandbox{Is sandbox
    sufficient?}

    is_quarantine{Is a quarantine
    ring available?}

    is_urgent{Is this an urgent
    production issue?}

    sandbox[Use sandbox environment]
    debug_quarantine[Use debug environment in quarantine ring or breakglass process]
    debug_non_quarantine[Use debug environment with ALLOW_NON_QUARANTINE override]
    create_mr[Create MR to cells/tissue to update Instrumentor version]

    start-->is_sandbox

    is_sandbox-->|Yes|sandbox
    is_sandbox-->|No|is_quarantine

    is_quarantine-->|Yes|debug_quarantine
    is_quarantine-->|No|is_urgent

    is_urgent-->|Yes|debug_non_quarantine
    is_urgent-->|No|create_mr
```

## Development flow

```mermaid
flowchart TD
    Start([Start Development]) --> CreateBranch[Create feature branch\nin instrumentor repo]
    CreateBranch --> UpdateCell[Update quarantine ring cell\nwith your branch name as version]
    UpdateCell --> MakeChanges[Make code changes, commit\nand push to remote branch]
    MakeChanges --> WaitBuild[Wait for CI/CD to build\nInstrumentor image from branch]
    WaitBuild --> RenderDebug[Execute render-debug script\nfor target cell and stage]
    RenderDebug --> RunStage[Execute stage script\ninside provisioned pod]
    RunStage --> DevComplete{Is development\ncomplete?}
    DevComplete -->|No, more changes needed| MakeChanges
    DevComplete -->|Yes, feature complete| End([End Development])
```

1. Pick a Cell to apply your changes to.
   - The cell should be in the quarantine ring
   - The cell should not be in use for development by any other team members
2. Create a branch for your change in [Instrumentor]
3. Update your quarantine ring cell to use your branch name as a version.
4. Make changes in your branch, commit and push to a remote branch.
5. Wait for your branch to be built into an Instrumentor image
6. Execute the `render-debug` script for the cell and stage you're targeting
7. Execute the stage script you are targeting inside the provisioned pod
8. Repeat steps 4-7 until development is complete.

## Best Practices

1. **Always prefer quarantine rings** for development and testing
2. **Document all changes** made using the debug environment
3. **Limit the duration** of debug access to the minimum necessary time
4. **Sync any manual changes back to IaC** once the immediate issue is resolved
5. **Coordinate with the team** before accessing non-quarantine rings
6. **Only use the debug script for `cellsdev`** unless in exceptional circumstances
7. **Justify your changes** with a valid issue link and description

## Usage

### Prerequisites

Before using the debug environment script, ensure you have:

1. `kubectl` and `gcloud` CLI tools installed
2. NordLayer VPN connection established to access the private gateway
3. PAM entitlement to access the AMP cluster (See [Breakglass - AMP](#getting-amp-access) section)
4. Appropriate Kubernetes permissions

If any of the above are missing the script will alert you and attempt to provision required permissions.

#### Required Environment Variables

| Variable        | Description                               | Example                   |
|-----------------|-------------------------------------------|---------------------------|
| `AMP_ENVIRONMENT` | The AMP environment to access             | `cellsdev` or `cellsprod` |
| `RING`            | The ring number (-1 for quarantine rings) | `-1`                      |
| `TENANT_ID`       | The ID of the tenant to access (cell ID)  | `12345`                   |


#### Optional Environment Variables

| Variable             | Description                                                                                | Default          |
|----------------------|--------------------------------------------------------------------------------------------|------------------|
| `ALLOW_NON_QUARANTINE` | Set to 'true' to allow access to non-quarantine rings                                      | `false`          |
| `SLEEP_TIME`           | Duration in seconds for the pod to remain alive                                            | `7200` (2 hours) |
| `ENTITLEMENT_DURATION` | Duration for the PAM entitlement (if requested). Should be at least as long as `$SLEEP_TIME` | `$SLEEP_TIME`    |



### Creating a Development Environment

```sh
# Required environment variables
export AMP_ENVIRONMENT="cellsdev"  # or "cellsprod"
export RING="-1"  # Use quarantine ring
export TENANT_ID="12345"  # Replace with actual tenant ID

# Optional: For shorter session duration (default is 2 hours)
export SLEEP_TIME=1800  # 30 minutes

# Execute the debug script with the desired stage
./scripts/render-debug.sh configure
```

### Accessing Non-Quarantine Rings

> [!warning]
> Using non-quarantine rings should only be done for urgent issues, as this provides direct access to rings that may be serving production traffic.
>
> It it recommended to move a cell to the quarantine ring instead of accessing it directly, if possible.

Non-quarantine rings are protected by default to prevent accidental changes. To access these rings:

```sh
export AMP_ENVIRONMENT="cellsdev"
export RING="2"  # Non-quarantine ring
export TENANT_ID="12345"
export ALLOW_NON_QUARANTINE=true
./scripts/render-debug.sh configure
```

## Getting AMP Access

To access the AMP cluster, you'll need to request PAM entitlement using the specific entitlement created for this purpose.

This will be automatically requested in the script, but is provided here:

```sh
gcloud beta pam grants create \
    --entitlement="gld-amp-stage-entitlement" \
    --requested-duration="1800s" \
    --justification="$ISSUE_LINK" \
    --location=global \
    --project="$AMP_PROJECT_ID"
```


[Instrumentor]: https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/instrumentor
[`cells/tissue`]: https://ops.gitlab.net/gitlab-com/gl-infra/cells/tissue
