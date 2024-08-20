# Infrastructure Development

This documentation is to provide rudimentary guidance where development inside of a sandbox, is for whatever reason, deemed not good enough.
Why this is may vary, one should use your sandbox as often as feasible.

[[ _TOC_ ]]

:warning: This is a tad dangerous as it Targets and entire Ring :warning:

## How-To

1. Do development inside of [Instrumentor] - use the standard documentation provided by [Instrumentor] where possible
1. Find the appropriate image from the MR Pipeline - note that branch names are modified, example `me/fix-thing` creates an image tag such as `me-fix-thing`
1. Create branch in [`cells/tissue`] - modify the [Instrumentor] version to the tag name from the above step
1. Ensure branch exists on the Ops repo of [`cells/tissue`] - non-protected branches are not mirrored
1. Execute `ringctl deploy -e <desired environment> --ring <desired_ring> -b me/fix-thing` to generate a test pipeline - this command will need to be modified pending your needs as by default `ringctl` assumes an auto-deploy

[Instrumentor]: https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/instrumentor
[`cells/tissue`]: https://gitlab.com/gitlab-com/gl-infra/cells/tissue
