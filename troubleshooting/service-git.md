---
title: Git Service
tags:
- troubleshooting
service: git
---
<!-- MARKER: do not edit this section directly. Edit services/service-mappings.yml then run scripts/generate-docs -->
* **Responsible Team**: [backend](https://about.gitlab.com/handbook/engineering/dev-backend/)
* **Slack Channel**: [#backend](https://gitlab.slack.com/archives/backend)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/WOtyonOiz/general-triage-service?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=git&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22git%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Git"
* **Sentry**: https://sentry.gitlab.net/gitlab/gitlabcom/?query=program%3A%22rails%22

## Logging

* [Rails](https://log.gitlab.net/goto/b368513b02f183a06d28c2a958b00602)
* [Workhorse](https://log.gitlab.net/goto/3ddd4ee7141ba2ec1a8b3bb0cb1476fe)
* [Unicorn](https://log.gitlab.net/goto/0cf60e9a1c94236eefb23348c39feaeb)
* [nginx](https://log.gitlab.net/goto/8a5fb5820ec7c8daebf719c51fa00ce0)
* [Unstructured Rails](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&advancedFilter=jsonPayload.hostname%3A%22git%22%0Alabels.tag%3D%22unstructured.production%22&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22)
* [system](https://log.gitlab.net/goto/bd680ccb3c21567e47a821bbf52a7c09)

{{< service git >}}

<!-- END_MARKER -->
