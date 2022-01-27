# customers.gitlab.com

## Overview
customers.gitlab.com is the site where GitLab customers can manage
their subscription(s) for GitLab.com.

### Production
Currently, the production node for this service is an Azure classic virtual
machine running in the `East US 2` zone. It can be connected to via SSH
directly as `customers.gitlab.com`.

From there, if you have the rights you can connect to the DB (a postgres v9.6/v10 
instance running locally in the VM) via:
`sudo su - postgres -c psql`

(only superusers have access to the DB. We are improving this soon)

See [this instructions](https://gitlab.com/gitlab-org/customers-gitlab-com/#accessing-production-as-an-admin-and-logs-and-console) to SSH the production box. The IP address can be found in [Cloudflare](https://dash.cloudflare.com/852e9d53d0f8adbd9205389356f2303d/gitlab.com/dns?recordsSearchSearch=customers).

#### Deployments

When a pipeline is triggered on the `staging` (default) branch of CustomersDot,
the application is first deployed to Staging then to Production after a delay of 2 hours.

That being said, it is possible to trigger a manual pipeline to deploy to
production right away, should the need to do so arise.

To deploy CustomersDot to Production only, create [a new CustomersDot pipeline](https://gitlab.com/gitlab-org/customers-gitlab-com/-/pipelines/new) with the following details:
- Branch: `master`
- CI variable: `DEPLOY_TO_PRODUCTION_NOW` set to `true`

It's important to note that the branch this pipeline needs to run on should be `master`, even if `staging` is the CustomersDot default branch.

If we're triggering this pipeline on `staging`, we're running the risk to overlap/override with other pending delayed deployment jobs, which are also using `staging`. By targeting 'master', we're getting rid of this risk as `master` is always behind `staging` while having its `HEAD` deployed to production.

### Staging
The staging node is a GCP machine.
It can be connected to via SSH using the [configuration stated in the CustomersDot repository](https://gitlab.com/gitlab-org/customers-gitlab-com/-/blob/staging/doc/testing/staging.md#ssh-config).

### Change Management
Chef is used to manage the production virtual machine. Chef
is also used to deploy the latest code to production.

[Ansible](https://gitlab.com/gitlab-com/gl-infra/customersdot-ansible-poc/) is used to deploy the latest code to staging.

#### Chef
[cookbook-customers-gitlab-com](https://gitlab.com/gitlab-cookbooks/cookbook-customers-gitlab-com)
is the Chef cookbook that configures the production and staging virtual
machines and deploys the staging and production builds of the application.

The old staging Chef environment is `stg` and the production Chef environment is
`_default`. Like our other Chef promotion workflows, the
[`stg` Chef environment](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/environments/stg.json)
is used to pin versions of recipes. Since the `_default` Chef environment
cannot be edited, production pins are managed in
[the Chef role](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/roles/customers-gitlab-com.json).

Making changes to the Chef recipe typical follows this workflow:
1. Create an MR for the cookbook-customers-gitlab-com project.
2. After approval, merge the MR.
3. The master branch changes will sync to the ops GitLab instance where
    MR's will be created in the [chef-repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/merge_requests) for staging and production.
4. Review, seek approval, and merge the Staging MR changes and verify the
    intended changes in staging.
5. Amend the production MR to include an update to the customers Chef role.
6. Review, seek approval, and merge the production MR. A production change
    issue may be required since the customers node is a single point of
    failure.
