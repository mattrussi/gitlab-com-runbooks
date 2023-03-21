# Praefect Database User Password Rotation

This document provides a runbook for rotating a database user password for the praefect service application.

The approach here intends to maintain uptime. Simply changing the password of the database user that Praefect is using would be disruptive to existing clients whenever new connections were established. Instead, create a new username and password, grant permissions from the old user to the new one, and then conduct a rolling reload of service instance configurations for each cluster member.

[A historical example of a change management plan issue for executing this runbook](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8280): `https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8280`

To the furthest extent possible, it is intended that an engineer may copy and paste the following tasks directly into a [change management plan issue](https://about.gitlab.com/handbook/engineering/infrastructure/change-management/) and follow the instructions verbatim to maximize efficiency and confidence in operations during a potentially high stress situation.

For the sake of precaution it is recommended to execute these change tasks for the `staging` environment first, before proceeding to execute in `production`.

For the purposes of this runbook, the username of the existing user is `praefect` and the username for the new user is `praefect_01`.

## Tasks

- [ ] Create a new user via terraform with a Merge Request to [the config-mgmt project](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/merge_requests). ([This will give them the `cloudsqlsuperuser` role automatically](https://cloud.google.com/sql/docs/postgres/create-manage-users#creating)) Paste the link to the MR here :point_right: `https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/merge_requests/0000`
- [ ] Have the MR reviewed, approved, and merged. Monitor the merge pipeline, and apply changes as necessary.
- [ ] Validate that the new user was created inside of cloudsql. It should be member of `cloudsqlsuperuser`

```sh
ssh console-01-sv-gprd.c.gitlab-production.internal
sudo dbconsole-praefect.sh
```

```sql
praefect=> \du+
```

The text `{cloudsqlsuperuser}` should appear in the column `Member of` in the output for the `Role Name` row entry for `praefect`.

- [ ] Grant the privileges of the `praefect` user to the new `praefect_01` user.

```sql
praefect=> GRANT "praefect" TO "praefect_01";
```

- [ ] Replace the link in the step below with a link for this change management plan issue.
- [ ] Pause chef-client on praefect nodes:

```sh
knife ssh 'role:gprd-base-stor-praefect' -- chef-client-disable 'https://gitlab.com/gitlab-com/gl-infra/production/-/issues/0000'
```

- [ ] Update the password in `bin/gkms-vault-edit gitlab-omnibus-secrets gprd`
- [ ] Update the `default_attributes.omnibus-gitlab.gitlab_rb.praefect.database_user` attribute in [gprd-base](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/gprd-base.json#L1121)
- [ ] Update the `default_attributes.gitlab_users.dbconsole_db_user_praefect` attributes in [gprd-base-console-node](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/gprd-base-console-node.json#L13), [gstg-base-console-node](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/gstg-base-console-node.json#L31), [gstg-base-console-ro-node](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/gstg-base-console-ro-node#L27), and [pre-base-console-node](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/pre-base-console-node#L35)
- [ ] Run `chef-client` on `praefect-01-stor-gprd.c.gitlab-production.internal` and validate that everything works:

```sh
ssh praefect-01-stor-gprd.c.gitlab-production.internal

```

```sh
sudo chef-client-enable
sudo chef-client
sudo grep 'user' /var/opt/gitlab/praefect/config.toml # Shoud be `praefect_01`
sudo gitlab-ctl praefect check # Should see `successfully read from database` and `successfully wrote to database`
```

- [ ] Also run `chef-client` on `console-ro-01-sv-gprd.c.gitlab-production.internal` to validate that the `dbconsole-praefect.sh` script has been configured as expected:

```sh
ssh console-01-sv-gprd.c.gitlab-production.internal
```

```sh
sudo chef-client-enable
sudo chef-client
sudo grep 'username' $(which dbconsole-praefect.sh)
```

The output should resemble:

```
CMD="/opt/gitlab/embedded/bin/psql --no-password --host=10.94.0.2 --port=5432 --username=praefect_01 praefect_production"
```

- [ ] Run `chef-client` on the rest of the nodes, and validate it works:

```sh
knife ssh -C1 'role:gprd-base-stor-praefect' -- sudo chef-client-enable
knife ssh -C1 'role:gprd-base-stor-praefect' -- sudo chef-client
knife ssh -C1 'role:gprd-base-stor-praefect' -- sudo grep 'user' /var/opt/gitlab/praefect/config.toml # Shoud be `praefect_01`
knife ssh -C1 'role:gprd-base-stor-praefect' -- sudo gitlab-ctl praefect check # Should see `successfully read from database` and `successfully wrote to database`
```

- [ ] Run `chef-client` on `praefect-01-stor-gprd.c.gitlab-production.internal` and validate that everything works:

```sh
ssh praefect-01-stor-gprd.c.gitlab-production.internal
sudo chef-client-enable
sudo chef-client
sudo grep 'user' /var/opt/gitlab/praefect/config.toml # Shoud be `praefect_01`
sudo gitlab-ctl praefect check # Should see `successfully read from database` and `successfully wrote to database`
```

- [ ] Run `chef-client` on the rest of the nodes, and validate it works:

```sh
knife ssh -C1 'role:gprd-base-stor-praefect-cny' -- sudo chef-client-enable
knife ssh -C1 'role:gprd-base-stor-praefect-cny' -- sudo chef-client
knife ssh -C1 'role:gprd-base-stor-praefect-cny' -- sudo grep 'user' /var/opt/gitlab/praefect/config.toml # Shoud be `praefect_01`
knife ssh -C1 'role:gprd-base-stor-praefect-cny' -- sudo gitlab-ctl praefect check # Should see `successfully read from database` and `successfully wrote to database`
```

- [ ] For each praefect service host system, restart the praefect service.  HUP is not sufficient to have the database connection re-established using the new user.

```sh
knife ssh -C1 'role:gprd-base-stor-praefect-cny' -- 'sudo gitlab-ctl restart praefect; sleep 20'
```

- [ ] Rotate the password for [the `praefect_01` user](https://console.cloud.google.com/sql/instances/praefect-db-9dfb/users?project=gitlab-production_: `https://console.cloud.google.com/sql/instances/praefect-db-9dfb/users?project=gitlab-production`
