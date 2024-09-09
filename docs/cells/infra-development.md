# Infrastructure Development

[[_TOC_]]

## Development

1. Create GitLab Dedicated [on-boarding issue].
1. Follow [Instrumentor Development] for sandbox development.

## Testing Instrumentor change in Cell without merge

:warning: This is a tad dangerous as it Targets and entire Ring :warning:

This provides rudimentary guidance where development inside of a sandbox, is for whatever reason, deemed not good enough.
Why this is may vary, one should use your sandbox as often as feasible.

1. Do development inside of [Instrumentor] - use the standard documentation provided by [Instrumentor] where possible
1. Find the appropriate image from the MR Pipeline - note that branch names are modified, example `me/fix-thing` creates an image tag such as `me-fix-thing`
1. Create a branch in [`cells/tissue`] - modify the [Instrumentor] version in a Cell in the [cellsdev ring](https://gitlab.com/gitlab-com/gl-infra/cells/tissue/-/tree/main/rings/cellsdev/0) to the tag name from the above step
1. Ensure branch exists on the Ops repo of [`cells/tissue`] - non-protected branches are not mirrored
1. Follow the instructions for [Provisioning a new Cell](https://gitlab.com/gitlab-com/gl-infra/cells/tissue/#provision-cell) - this creates a full pipeline

[Instrumentor]: https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/instrumentor
[`cells/tissue`]: https://gitlab.com/gitlab-com/gl-infra/cells/tissue
[on-boarding issue]: https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/blob/8168e8e318f79136cd50f6cc59351796b2e85422/.gitlab/issue_templates/non-Dedicated_GitLab_team_member_onboarding.md
[Instrumentor Development]: https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/instrumentor/-/blob/main/DEVELOPMENT.md
