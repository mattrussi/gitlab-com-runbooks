# Application logging at gitlab

## Summary

**https://log.gitlab.net**

Centralized logging at GitLab uses a combination of FluentD, google pubsub,
and ElasticSearch / Kibana. All logs for the production, staging, gprd and
gstg environments are forwarded to log.gitlab.net.

### What are we logging?

| name | logfile  | type  | index | retention(d) |
| -----| -------- |------ | ----- | --------- |
| gitaly | gitaly/current | JSON | pubsub-gitaly-inf | 3
| pages | gitlab-pages/current | JSON | pubsub-pages-inf | 6
| db.postgres | postgresql/current | line regex | pubsub-postgres-inf | 6
| db.pgbouncer | gitlab/pgbouncer/current | line regex | pubsub-postgres-inf | 6
| workhorse | gitlab/gitlab-workhorse/current | JSON | pubsub-workhorse-inf | 3
| api |gitlab-rails/api\_json.log | JSON | pubsub-api-inf | 6
| geo | gitlab-rails/geo.log | JSON | pubsub-geo-inf | 6
| production (rails) | gitlab-rails/production\_json.log | JSON | pubsub-production-inf | 6
| sidekiq gitlab/sidekiq|cluster/current | JSON | pubsub-sidekiq-inf | 6
| haproxy | /var/log/haproxy.log | syslog | pubsub-haproxy-inf | 3
| system.auth | /var/log/auth.log | syslog | pubsub-system-inf | 6
| system.syslog | /var/log/syslog | syslog | pubsub-system-inf | 6


### FAQ

#### How do I find the right logs for my service?

* Navigate to https://log.gitlab.net
* Select the appropriate index (see chart below).
  * Azure production and GCP production logs are in the *gprd* `*-gprd*` indexes
  * Azure staging and GCP staging logs are in the *gstg* `*-gstg*` indexes
* Optionally filter by environment if you only want to see logs for azure or gcp.
  * `+json.environment: prd` for Azure production
  * `+json.environment: gprd` for Google production

#### A user sees an error on GitLab com, how do I find logs for that user?

* Select the `pubsub-production-inf-grpd*` index
* Search for `+json.username: <user>`

#### Why do we have these annoying json. prefixes?

They are created by https://github.com/GoogleCloudPlatform/pubsubbeat , I don't see a way we can remove them without forking the project.


### Chef configuration

There are three cookbooks that configure logging on gitlab.com

*
#### Cookbooks

#### Role configuration

### Terraform

### Monitoring and Troubleshooting

* To ensure that pubsub messages are being consumed and sent to elasticsearch see the [stackdriver pubsub dashboards](https://app.google.stackdriver.com/monitoring/1088234/logging-pubsub-in-gprd?project=gitlab-production)
* Monitoring of td-agent (TBD) https://gitlab.com/gitlab-com/migration/issues/390
* Monitoring of pubsub (TBD) https://gitlab.com/gitlab-com/migration/issues/389

#### Logs have stopped showing up on elastic search

* Find the appropriate beat for the index, look for the vm that matches the index name
* SSH to the vm and look at the `/var/log/pubsub/current` logfile to see if there are any errors.
* If there are no errors check out the `/var/log/tg-agent` logfile on one of the nodes sending logs.
