# Mimir recording rules

This directory contains the source files that will generate the recording rules on the directory [mimir-rules](https://gitlab.com/gitlab-com/runbooks/-/tree/master/mimir-rules?ref_type=heads).

Mimir uses the so called [tenant](https://grafana.com/docs/mimir/latest/references/glossary/#tenant) as an abstraction to a set of series (our recording rules). Each tenant is isolated from each other, allowing us to parallelize work as see fit to scale.

At GitLab, we use a combination of cluster, environment, service, and filename as a tenant. The helper function [separateMimirRecordingFiles](https://gitlab.com/gitlab-com/runbooks/-/blob/master/libsonnet/recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet?ref_type=heads#L18) provides the building blocks to split the rules by tenants, generating the recording rule files with a valid unique name that works as a namespace for each rule group.

## Further reading

- [Grafana Mimir oficial docs](https://grafana.com/docs/mimir/latest/)
