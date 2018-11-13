---
title: Redis Service
tags:
- troubleshooting
service: redis
---
<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
* **Responsible Team**: [infrastructure](https://about.gitlab.com/handbook/engineering/infrastructure/)
* **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=redis&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22redis%22%2C%20tier%3D%22db%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Redis"
* **Grafana Folder**: https://dashboards.gitlab.net/dashboards/f/D5R0peIik

## Logging

* [Redis](https://log.gitlab.net/goto/27a6bf4e347ef9da754f06eb0a54aedc)
* [system](https://log.gitlab.net/goto/e107ce00a9adede2e130d0c8ec1a2ac7)

## Troubleshooting Pointers

* [ci_graphs.md]({{< relref "troubleshooting/ci_graphs.md" >}})
* [ci_introduction.md]({{< relref "troubleshooting/ci_introduction.md" >}})
* [large-pull-mirror-queue.md]({{< relref "troubleshooting/large-pull-mirror-queue.md" >}})
* [postgres.md]({{< relref "troubleshooting/postgres.md" >}})
* [redis_replication.md]({{< relref "troubleshooting/redis_replication.md" >}})
* [sentry-is-down.md]({{< relref "troubleshooting/sentry-is-down.md" >}})
* [sidekiq_stats_no_longer_showing.md]({{< relref "troubleshooting/sidekiq_stats_no_longer_showing.md" >}})
<!-- END_MARKER -->
