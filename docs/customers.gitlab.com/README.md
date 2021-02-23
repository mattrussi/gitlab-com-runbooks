# customers.gitlab.com

## Overview
customers.gitlab.com is the site where GitLab customers can manage
their subscription(s) for GitLab.com.

### Production
Currently, the production node for this service is an Azure classic virtual
machine running in the `East US 2` zone. It can be connected to via SSH
directly as `customers.gitlab.com`.

### Staging
The staging node is an Azure virtual machine running in the `East US 2` zone.
It can be connected to via SSH directly as `customers.stg.gitlab.com`.

### Change Management
Chef is used to manage both the staging and production virtual machines. Chef
is also used to deploy the latest code to staging and production.

#### Chef
[cookbook-customers-gitlab-com](https://gitlab.com/gitlab-cookbooks/cookbook-customers-gitlab-com)
is the Chef cookbook that configures the production and staging virtual
machines and deploys the staging and production builds of the application.

The staging Chef environment is `stg` and the production Chef environment is
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
