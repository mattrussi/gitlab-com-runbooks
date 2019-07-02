#Access Requests

## Add or verify data bag
1. Check ssh key
1. Check unix groups
1. knife data bag from file users <user>.json

## Chef Access
```
# on chef.gitlab.com
chef-server-ctl user-create <username> <first> <last> <email> $(openssl rand -hex 20)
# copy the output into <username>.pem and drop it in their home directory on deploy
chef-server-ctl org-user-add gitlab <username>
```

## System access granted via groups with Chef

We have [user data bags](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/tree/master/data_bags/users)
which we use to grant access to systems via chef.  

Inside each user data bag there is a "groups" array we can assign a user to.
These groups will add that person's linux user to a different set of hosts / different unix group on the host.
The [gitlab_users](https://ops.gitlab.net/gitlab-cookbooks/gitlab_users) cookbook
looks for these groups and will deploy linux users and their ssh key when the groups is assigned to the user.
A node's groups are assigned mostly via its role.

For example: on production dbs, the [base role](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/roles/gprd-base-db.json#L5)
defines the "production" and "database" groups for who will access nodes in that role.

The current set of groups allowed are:

1. build - chef roles: 
1. ceph-deploy
1. ceph-dev
1. ci
1. console
1. contributors
1. database
1. db-console
1. db-console-archive
1. db-console-geo
1. db-console-primary
1. dbconsole
1. developer
1. dr-bastion-only
1. gitlab-qa-tunnel
1. gitlab-ssh-users
1. gprd-bastion-only - allow ssh access through production bastion to production
1. gstg-bastion-only - allow ssh access through staging bastion to staging env
1. import
1. internal-apps - allow ssh access to internal apps **
1. monitoring
1. nessus
1. nfs
1. omnibus-admin
1. ops
1. pre
1. pre-bastion-only
1. production
1. rails-console
1. release-manager
1. staging
1. support

** internal apps are:  customers.gitlab.com, license.gitlab.com

## COG Access
1. User talks to @marvin
1. Admin adds user (keep in mind slack name may be different from unix or email name)
1. !group-member-add <group> <user>
