# Application logging at gitlab

## Summary


## What are we logging
* gitaly - gitaly/current [JSON]
* pages - gitlab-pages/current [JSON]
* db.postgres - postgresql/current [line regex]
* db.pgbouncer - gitlab/pgbouncer/current [line regex]
* workhorse - gitlab/gitlab-workhorse/current [JSON]
* api -gitlab-rails/api_json.log [JSON]
* geo - gitlab-rails/geo.log [JSON]
* production (rails) - gitlab-rails/production_json.log [JSON]
* sidekiq gitlab/sidekiq-cluster/current [JSON]
* haproxy - /var/log/haproxy.log [syslog]
* system.auth - /var/log/auth.log [syslog]
* system.syslog - /var/log/syslog [syslog]


## Where do I find logs

https://log.gitlab.net

### Chef configuration

#### Cookbooks

#### Role configuration

### Terraform

### Monitoring and Troubleshooting
