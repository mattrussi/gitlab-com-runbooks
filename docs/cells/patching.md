# Patch Cell's Tenant Model

## Overview

Changes to a Cell's `TENANT_MODEL` are applied through a [`JSON6902` patch](https://datatracker.ietf.org/doc/html/rfc6902). Patches are applied from inner rings to outer rings, starting with `ring 0` and proceeding outward sequentially.

If a patch application fails at any ring, the entire process halts and requires manual intervention.

> [!note]
> Patches are not applied to the quarantine ring (-1). To update the `TENANT_MODEL` of a Cell in the quarantine ring, open a Merge Request and update it directly.

## Prerequisites

- Configure [`ringctl` in your environment](https://gitlab.com/gitlab-com/gl-infra/ringctl#preparing-your-environment)
- Ensure you have access to [`cells/tissue`](https://ops.gitlab.net/gitlab-com/gl-infra/cells/tissue/)

## Patch Operations

The following patch operations are available using [`ringctl`](https://gitlab.com/gitlab-com/gl-infra/ringctl):

| Operation | Description | Parameters |
|-----------|-------------|------------|
| `add` | Add a new field to the `TENANT_MODEL` | Target path, Value |
| `replace` | Replace a field's value | Target JSON path, Value |
| `remove` | Remove a field | JSON path |
| `move` | Move a field to a new location | Source path, Destination path |
| `copy` | Copy a field to a new location | Source path, Destination path |

## Creating a Patch

Use the `ringctl patch create` subcommand with the desired operation.

### Basic Examples

Update a single value:

```bash
ringctl patch create replace /instrumentor_version v16.xxx.x -e <cellsdev|cellsprod> --related-to "<issue_url>"
```

Combine multiple operations in one patch:

```bash
ringctl patch create add /use_gar_for_prerelease_image true replace /instrumentor_version v16.xxx.x --related-to <issue_id> --priority <3> -e <cellsdev|cellsprod>
```

Add a complex JSON structure:

```bash
ringctl patch create add "/byod" '{"instance": "gitlab.com"}' --related-to <issue_id> --priority <3> -e <cellsdev|cellsprod>
```

The command will create a Merge Request in [`cells/tissue`](https://ops.gitlab.net/gitlab-com/gl-infra/cells/tissue/). Get it reviewed and merged into `main`. Note the `patch_id` for tracking.

## Checking Patch Status

View all patches and their statuses:

```bash
ringctl patch ls -e <cellsdev|cellsprod>
```

> [!note]
> Only one patch can be "In Progress" for a particular ring at any time.
> Patches run sequentially according to their priority.
> For urgent patches, consider setting priority to 3.

Each applied patch triggers the `Instrumentor` Stages pipeline. Find the pipeline on [`tissue`](https://ops.gitlab.net/gitlab-com/gl-infra/cells/tissue/-/pipelines) by searching for your `patch_id`.

## Deleting a Patch

Delete a patch that's still in `pending` status:

```bash
ringctl patch delete <patch_id> -e <cellsdev|cellsprod>
```

> [!warning]
> A patch in the "in rollout" state cannot be stopped, as the Instrumentor stages pipeline is already running.
