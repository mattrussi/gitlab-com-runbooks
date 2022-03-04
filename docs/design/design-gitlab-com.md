# design.gitlab.com Runbook

### Overview

The `design.gitlab.com` runs Pajamas Design System and contains brand and product design guidelines and UI components for all things GitLab. The project is located in [https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com](https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com). You can read more this system [here](https://about.gitlab.com/handbook/engineering/ux/pajamas-design-system/).

This is an internally developed Rails app which is running on a GKE cluster, using an unmodified Auto DevOps deployment configuration.

### Setup for On Call

- Read the README file for the [GitLab Services Base](https://ops.gitlab.net/gitlab-com/services-base) project
- Note the location of the [Metrics Dashboards](https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com/-/metrics?environment=269942)
- Note the location of the [CI Pipelines for the infrastructure](https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com) components
- Note the location of the [CI Pipelines for the application](https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com/-/pipelines) components

For more detailed information on the setup view the [version.gitlab.com runbooks](../version/version-gitlab-com.md).
