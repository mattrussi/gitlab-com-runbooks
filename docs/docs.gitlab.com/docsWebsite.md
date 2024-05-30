# GitLab Docs website troubleshooting

**Table of Contents**

[TOC]

## Overview

The GitLab Docs websites, [docs.gitlab.com](https://docs.gitlab.com) and [archives.docs.gitlab.com](https://archives.gitlab.com) host documentation about the GitLab product. Help links within the GitLab product point to pages on these sites.

Both are static sites that are published to GitLab Pages on GitLab.com.

## Deployments

The primary site, `docs.gitlab.com` [deploys hourly](https://docs.gitlab.com/ee/development/documentation/site_architecture/deployment_process.html) via a [scheduled pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipeline_schedules).

The Archives site, `archives.docs.gitlab.com` deploys on merge to `main` and is typically only updated when new GitLab versions are released.

## Support

The GitLab Docs websites are developed and maintained by the [Technical Writing team](https://handbook.gitlab.com/handbook/product/ux/technical-writing/).

## Considerations

`docs.gitlab.com` is very large in size, and it deploys frequently. Previous availability incidents have been tracked back to GitLab Pages issues that have only impacted large sites (e.g, issues caused by how long it can take to upload the build artifact).

### Alerting

The primary docs website, `docs.gitlab.com`, is monitored with a blackbox probe.

## Resources

- [GitLab Docs project](https://gitlab.com/gitlab-org/gitlab-docs)
- [Docs Archives project](https://gitlab.com/gitlab-org/gitlab-docs-archives)
- [Docs site infrastructure](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/infrastructure.md?ref_type=heads)
- [Docs site architecture](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/architecture.md?ref_type=heads)
