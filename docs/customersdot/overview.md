# CustomersDot main troubleshoot documentation

## Overview

customers.gitlab.com is the site where GitLab customers can manage
their subscription(s) for GitLab.com.

For all availability issues see the **[escalation process for incidents or outages](https://about.gitlab.com/handbook/engineering/development/fulfillment/#escalation-process-for-incidents-or-outages)**.

### Production and Staging

The production and staging environments reside in Google Cloud projects.

* Staging: gitlab-subscriptions-staging
* Production: gitlab-subscriptions-prod

#### SSH

For remote access to the VMs, refer to
[these instructions](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/staging/doc/testing/staging.md#ssh-config)

#### CDN

Both staging and production services are proxied through Cloudflare. Refer to
the section for NGINX below for rate limit information.

#### NGINX

The web server on the VM has a rate limit set that should return a 429
when the rate is exceeded. This rate limit is specific to API Seat Requests
and is is managed in
[Ansible](https://gitlab.com/gitlab-com/gl-infra/customersdot-ansible).

#### Logs

* Local Logs
  * NGINX Logs: `/var/log/nginx`
  * PostgreSQL Logs: `/var/log/postgresql`
  * CustomersDot Logs: `/home/customersdot/CustomersDot/current/log`
* Stackdriver Logs
  * Application Logs from the VM are shipped into Stackdriver in GCP.
  * <https://cloudlogging.app.goo.gl/Jew7kUFaW8SUgeew9>

#### Metrics

Specifications for a Customersdot metric catalog is available at [`metrics-catalog/services/customersdot.jsonnet`](../../metrics-catalog/services/customersdot.jsonnet).

This catalog references the `customers_dot_requests_apdex` SLI, introduced as a
[Rails application SLI](https://docs.gitlab.com/ee/development/application_slis/#gitlab-application-service-level-indicators-slis) for CustomersDot (see [Collector class](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/main/lib/metrics/collector.rb) for more details).

Two Prometheus instances have been set up for CustomersDot:

* [Prometheus instance for Staging](https://prometheus-gke.stgsub.gitlab.net/graph)
* [Prometheus instance for Production](https://prometheus-gke.prdsub.gitlab.net/graph)

#### Database Access

Once you have logged into a VM, if you have the rights you can connect to the
Postgres database via:

```bash
sudo su - postgres -c psql
```

(only superusers have access to the DB. We are improving this soon)

#### Deployments

When a pipeline is triggered on the `staging` (default) branch of CustomersDot,
the application is first deployed to Staging then to Production after a delay of
2 hours.

That being said, it is possible to trigger a manual pipeline to deploy to
production right away, should the need to do so arise. To do so, please refer to
[this documentation](https://gitlab.com/gitlab-com/gl-infra/customersdot-ansible/-/blob/master/doc/readme.md#manual-deployment-to-production).

### Change Management

Terraform is used to provision the virtual infrastructure for staging and
production:

* [Staging](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/stgsub)
* [Production](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/prdsub)

Chef is used essentially to bootstrap user access for users and Ansible.

* [Staging Base](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/stgsub-base.json)
* [Production Base](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/prdsub-base.json)

[Ansible](https://gitlab.com/gitlab-com/gl-infra/customersdot-ansible) is used to deploy the latest code to staging.

### Alerting

Currently, the only alerting is a blackbox probe.
