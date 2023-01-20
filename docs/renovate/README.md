# Renovate Bot

We use [Renovate](https://github.com/renovatebot/renovate) to keep our project's
dependencies automatically up-to-date. A daily scheduled CI job scans projects
under the `gitlab-com/gl/infra` namespaces, both
[on GitLab.com](https://gitlab.com/gitlab-com/gl-infra/renovate/renovate-ci) and
[on ops.gitlab.net](https://ops.gitlab.net/gitlab-com/gl-infra/renovate/renovate-ci),
and automatically creates dependency update MRs if needed.

## Adding dependencies

To configure Renovate Bot for a given project:

- Add a `renovate.json` file to the root of the project. Renovate should
  autodetect the most common dependency files (`Gemfile`, `Dockerfile`, etc),
  but you can also configure any extra files or settings as needed.
  See [the configuration
  options documentation](https://docs.renovatebot.com/configuration-options/)
  for further reference.

- Annotate dependencies in the project's files as needed, matching your
  `renovate.json` configuration.

For an example configuration see
[here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/ef14a5d1f1791d4a0972483f669648e1ece68e47/renovate.json),
and for an example matching annotation see
[here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/986a4d0e362b1cb0316e662390c00fb2ad445a90/.gitlab-ci.jsonnet#L37-38).

## Troubleshooting

If you configured a dependency and it isn't getting picked up by renovate-ci,
check the output of the latest scheduled pipeline job [on
GitLab.com](https://gitlab.com/gitlab-com/gl-infra/renovate/renovate-ci/-/pipeline_schedules)
or
[on ops.gitlab.net](https://ops.gitlab.net/gitlab-com/gl-infra/renovate/renovate-ci/-/pipeline_schedules).
If you need further debug data, check the `renovate-log.ndjson` file on the CI
job's artifacts and grep for the project's name.

If you suspect your `renovate.json` may need adjustments, you can try them out
before merging them the following way:

- `npm install -g renovate`
- On a local copy of <https://gitlab.com/gitlab-com/gl-infra/renovate/renovate-ci>,
  execute

```
RENOVATE_PLATFORM=gitlab RENOVATE_TOKEN=<your-gitlab-token> RENOVATE_REPOSITORIES=gitlab-com/gl-infra/<path-to-project> RENOVATE_BASE_BRANCHES=<your-branch> renovate --use-base-branch-config=merge --autodiscover=false --dry-run=full
```
