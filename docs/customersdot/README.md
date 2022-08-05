<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Customersdot Service

* [Service Overview](https://dashboards.gitlab.net/d/customersdot-main/customersdot-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22customersdot%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service:Customersdot"

## Logging

* [Rails](https://console.cloud.google.com/logs/query;query=resource.type%3D%22gce_instance%22%0Alog_name%3D%22projects%2Fgitlab-subscriptions-prod%2Flogs%2Frails.production%22;cursorTimestamp=2022-06-08T08:35:26.081Z?referrer=search&project=gitlab-subscriptions-prod)
* [Sidekiq](https://console.cloud.google.com/logs/query;query=resource.type%3D%22gce_instance%22%0Alog_name%3D%22projects%2Fgitlab-subscriptions-prod%2Flogs%2Fsidekiq.production%22;cursorTimestamp=2022-06-08T08:34:39.368440702Z?referrer=search&project=gitlab-subscriptions-prod/)

## Troubleshooting Pointers

* [CustomersDot main troubleshoot documentation](overview.md)
* [../patroni/postgresql-backups-wale-walg.md](../patroni/postgresql-backups-wale-walg.md)
<!-- END_MARKER -->

<!-- ## Summary -->

<!-- ## Architecture -->

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
