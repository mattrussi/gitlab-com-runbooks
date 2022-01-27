# Reference Architecture Monitoring

This directory contains configuration to provide observability into other GitLab instances (not GitLab.com).

This is based off the same Service-Level Monitoring and Saturation Monitoring metrics used to monitor GitLab.com.

Each sub-directory contains a specific reference architecture, although for now, there is only one:

1. [`get-hybrid/`](get-hybrid/): this provides monitoring configuration, dashboards and alerts for a [GitLab Environment Toolkit (GET) Hybrid Kubernetes environment](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/blob/main/docs/environment_advanced_hybrid.md).

## Warning about Completeness

This is, at present, a work-in-progress. The plan is to start with a small subset of required metrics and expand it until the configuration covers all metrics critical to the operation of a GitLab instance.

The epic tracking this effort is here: <https://gitlab.com/groups/gitlab-com/-/epics/1721>. For up-to-date progress on the effort, consult the epic.
