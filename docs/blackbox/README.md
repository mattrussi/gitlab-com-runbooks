<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Blackbox Service

* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22blackbox%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::Blackbox"

## Logging

* [system](https://log.gprd.gitlab.net/goto/b4618f79f80f44cb21a32623a275a0e6)

## Troubleshooting Pointers

* [Blackbox git exporter is down](blackbox-git-exporter.md)
* [design.gitlab.com Runbook](../design/design-gitlab-com.md)
* [CI Artifacts CDN](../google-cloud-storage/artifacts-cdn.md)
* [Investors Relations (ir.gitlab.com) main troubleshoot documentation](../ir.gitlab.com/overview.md)
* [Tuning and Modifying Alerts](../monitoring/alert_tuning.md)
* [An impatient SRE's guide to deleting alerts](../monitoring/deleting-alerts.md)
* [../patroni/postgres.md](../patroni/postgres.md)
* [../patroni/postgresql-backups-wale-walg.md](../patroni/postgresql-backups-wale-walg.md)
* [Container Registry CDN](../registry/cdn.md)
* [../spamcheck/index.md](../spamcheck/index.md)
* [GitLab Job Completion](../uncategorized/job_completion.md)
* [version.gitlab.com Runbook](../version/version-gitlab-com.md)
<!-- END_MARKER -->

## Result logs

The blackbox exporter keeps logs from failed probes in memory and exposes them over an HTTP interface.

You can access it by using port forwarding, and then navigating to `http://localhost:9115`:

```
ssh blackbox-01-inf-gprd.c.gitlab-production.internal -L 9115:localhost:9115
```

Please note that the exporter will only keep up to 1000 results, and drop older
ones. So make sure to grab these as quickly as possible, before they expire.

<!-- ## Summary -->

<!-- ## Architecture -->

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
