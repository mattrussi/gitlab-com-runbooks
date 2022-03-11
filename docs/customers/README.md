# customers.gitlab.com

## Overview
customers.gitlab.com is the site where GitLab customers can manage
their subscription(s) for GitLab.com.

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
  - NGINX Logs: `/var/log/nginx`
  - PostgreSQL Logs: `/var/log/postgresql`
  - CustomersDot Logs: `/home/customersdot/CustomersDot/current/log`
* Stackdriver Logs
  - Application Logs from the VM are shipped into Stackdriver in GCP.
  - https://cloudlogging.app.goo.gl/Jew7kUFaW8SUgeew9

#### Metrics
Metrics are currently limited, only some are exported (node-exporter),
no dashboards exist that can be referenced. Building out metrics and dashboards
are TODO tasks.

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
production right away, should the need to do so arise.

To deploy CustomersDot to Production only, create
[a new CustomersDot pipeline](https://gitlab.com/gitlab-org/customers-gitlab-com/-/pipelines/new)
with the following details:
- Branch: `master`
- CI variable: `DEPLOY_TO_PRODUCTION_NOW` set to `true`

It's important to note that the branch this pipeline needs to run on should be
`master`, even if `staging` is the CustomersDot default branch.

If we're triggering this pipeline on `staging`, we're running the risk to
overlap/override with other pending delayed deployment jobs, which are also
using `staging`. By targeting 'master', we're getting rid of this risk as
`master` is always behind `staging` while having its `HEAD` deployed to
production.

### Change Management
Terraform is used to provision the virtual infrastructure for staging and
production:
* [Staging](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/stgsub)
* [Production](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/prdsub)

Chef is used essentially to bootstrap user access for users and Ansible.
* [Staging Base](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/stgsub-base.json)
* [Production Base](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/prdsub-base.json)

[Ansible](https://gitlab.com/gitlab-com/gl-infra/customersdot-ansible)
is used to deploy the latest code to staging.
