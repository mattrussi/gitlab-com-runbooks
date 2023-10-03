# Gitaly servers healthcheck

## Experiment

- Move traffic away from a single zone e.g. `us-east1-b`.
- Move Gitaly nodes to a new zone.

## Agenda

- Revisit Gitaly Multi Project
  - <https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/library/gitaly-multi-project/README.md>
  - <https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/gitaly-snapshot-restore>
- Discuss hypothesis

## Hypothesis

The engineer on call should get a message in prometheus-alerts that Gitaly is down on the affected nodes.

## Preparation

1. Create issue in <https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/new>
1. Identify and inform the SRE on-call during that day running gameday.
