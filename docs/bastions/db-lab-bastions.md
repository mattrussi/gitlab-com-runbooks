# db-lab bastion hosts

For a user to login to the `db-lab` hosts, a user's ssh key needs to be in the chef-repo [users data_bags](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/tree/master/data_bags/users?ref_type=heads), and the groups should include `db-lab` role.

```json
"groups": [
    "db-lab"
  ]
```

If the user's ssh key is not present in the data bags this [runbook](https://ops.gitlab.net/gitlab-com/gl-infra/chef-repo/-/blob/master/doc/user-administration.md#add-the-ssh-key-to-the-chef-repo) explains how to add ssh keys to the chef-repo.
**NOTE:** an [access request](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/new?issuable_template=Individual_Bulk_Access_Request) is required when adding ssh keys to the chef-repo.

## How to configure ssh login

Add the following to your `~/.ssh/config` (specify your username and path to ssh private key):

```text
# lab bastion host
Host lb-bastion.db-lab.gitlab.com
  User                            YOUR_SSH_USERNAME
  IdentityFile                    ~/.ssh/id_rsa

# lab boxes
Host *.gitlab-db-lab.internal
        User                            YOUR_SSH_USERNAME
        PreferredAuthentications        publickey
        IdentityFile                    ~/.ssh/id_rsa
        ProxyCommand                    ssh lb-bastion.db-lab.gitlab.com -W %h:%p
```

Once your config is in place, test it by connecting via SSH to the bastion host:

```bash
ssh lb-bastion.db-lab.gitlab.com
```
