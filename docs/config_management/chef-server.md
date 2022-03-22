# Chef Server
The Chef server is hosted in the `gitlab-ops` [GCP project](https://console.cloud.google.com/home/dashboard?project=gitlab-ops). The server is a
standalone server and runs the embedded PostgreSQL database service locally.

## Cookbook
The [ops-infra-chef](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/roles/ops-infra-chef.json)
role contains the runlist for the Chef server. The
[gitlab-chef-server](https://gitlab.com/gitlab-cookbooks/gitlab-chef-server)
cookbook installs and manages the Chef services and the Let's Encrypt
certificate renewal.

## Recovery
[Snapshots](https://console.cloud.google.com/compute/snapshots?folder=&organizationId=&project=gitlab-ops) of the data disk are taken every four hours. This should allow some
capacity to restore the Chef server in the event of the VM being deleted/lost.

It is also possible to re-upload all of the cookbooks we need as well as roles
and environments with the [chef-repo](https://ops.gitlab.net/gitlab-com/gl-infra/chef-repo) project.

- [Terraform](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules) can rebuild/replace the load balancer, VM, and DNS.
- [Bootstrapping](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/bootstrap) the `gitlab-chef-server` cookbook or rebuilding from a snapshot
    can restore the Chef server service.
- The [chef-repo](https://ops.gitlab.net/gitlab-com/gl-infra/chef-repo) project can re-store cookbooks, environments, roles, etc.

## Roles and Responsibilities
- TBD
