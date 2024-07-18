# Connecting To a Database via Teleport

**Table of Contents**

[TOC]

## Background on Teleport

Database consoles in `gprd`, `gstg`, and other environments are accessed via [Teleport](https://goteleport.com/teleport/docs/).
Access to Database consoles by SSH'ing into the console servers will be removed in future (for the majority of use cases).

- The main reasons for this change are security and compliance:
  With Teleport we have fully flexible, on-demand, and audited access to our Database consoles and to some other terminal/CLI tools,
  like `kubectl`, [Rails Console](Connect_to_Rails_Console_via_Teleport.md), and more.
- Teleport's goal is to provide a *Unified Access Plane* for all of our infrastructure.
  [Here](https://goteleport.com/docs/) you can find some of the most popular use cases for Teleport.
- We evaluated Teleport thoroughly (see this [issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11568))
  and found it to comply with most of our infrastructure access requirements,
  unlike some of its competitors ([Okta-ASA](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/12042),
  [Hashicorp Boundary](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11666) and others).

## Access Requests

Before you start using Teleport, you must be assigned the app in Okta. This should be a part of your role's baseline group assignment.
In most cases there should be no additional action required to gain access to the services appropriate to your role.
If your onboarding is complete and you still do not have access to the Teleport app in Okta, open an
[access request](https://handbook.gitlab.com/handbook/business-technology/end-user-services/onboarding-access-requests/access-requests/)
and follow the appropriate approval methods.

Note that trying to login to the Teleport Console from Okta dashboard can fail with a message "Login Unsuccessful",
this is totally expected and does not mean you need to open an access request.

## Connect To Database Console

You need the Teleport CLI client [tsh](https://goteleport.com/docs/reference/cli/tsh/) for connecting to a Database console.

### Installing tsh

Official packages for [macOS](hhttps://goteleport.com/docs/installation/#macos) and
[Linux](https://goteleport.com/docs/installation/#linux) can be found at Teleport's website.

### Installing psql

You also need `psql` for accessing a Database shell.
Please ensure you install it with [Homebrew](https://brew.sh) and not other tools such as `mise` or `asdf`.

```shell
brew install postgresql@14
```

### Accessing The Database Console

NOTE: we now have only one Teleport instance available at <https://production.teleport.gitlab.net>.

The typical workflow for accessing a database is as follows.

1. Authenticate to the Teleport instance.
2. Submit an access request for the database role that you need.
3. After your request is approved, log in to the database with the appropriate database user.
4. Connect to the database shell.

The read-only access to non-production (`gstg` or `pre`) databases is given to everyone by default via the `non-prod-database-ro` role.
Hence, you do NOT need to submit an access request for read-only access in non-production environments (`gstg` or `pre`).
If read-write access or production data are strictly necessary for the job, submit an access request using Teleport for the appropriate role.

The access will be temporary (12 hours) and can be approved by any SRE or Reliability Manager.
If the request is urgent, you can ping `@sre-oncall`, but to spread out the workload,
please try to allow some time for others to review first if possible.
Access can be extended before or after expiration using the same process.

#### Non-Production

1. Authenticate to the Teleport instance. This command opens Okta in a browser window:

```bash
$ tsh login --proxy=production.teleport.gitlab.net
```

2. Request approval for the database role that you need.

Note: The `non-prod-database-ro` role in the `gstg` or `pre` environments does not require a request or approval, so you can skip this step.
Use the `non-prod-database-ro` role unless you know for sure that you need something else.
For Package Team members, they additionaly have `non-prod-database-registry-ro` role in the `gstg` and `pre`,
which gives them access to registry database without approval.

Request any of the following roles, if you need a role which includes elevated permissions for the database console.

Non-production (`gstg` or `pre`) `main` and `CI` database roles:

- Read-only:  `non-prod-database-ro`
- Read-Write: `non-prod-database-rw`

Non-production (`gstg` or `pre`) `registry` database roles:

- Read-only:  `non-prod-database-registry-ro`
- Read-Write: `non-prod-database-registry-rw`

```bash
$ tsh login --proxy=production.teleport.gitlab.net --request-roles=non-prod-database-rw --request-reason="GitLab Issue URL or ZenDesk Ticket URL"
```

This command will pause while it waits for the reviewer to approve the request.
It may appear to hang, but it is waiting for someone to approve it.
The command will return as soon as the request is approved, denied, or expires.

If the command is stopped or times out, but the request is approved, you do not need to request another approval.
Simply login and provide the approved request ID (output by the previous command, or find it in the web interface).

3. Login with the approved request ID.

The request ID is shown in the output of `tsh login` when making the initial request, and can also be found attached to
your request notification in [#teleport-requests](https://gitlab.enterprise.slack.com/archives/C06Q2JK3YPM).

```bash
$ tsh login --request-id=<request-id>
```

4. Login to the database.

Once an approval (if required) is issued, the next step is to log in to the database.
The database name at the end of the line refers to the database host that Teleport is pointing to (which you can see with `tsh db ls`).

```bash
# Main Database
$ tsh db login --db-user=console-rw --db-name=gitlabhq_production db-main-replica-gstg

# CI Database
$ tsh db login --db-user=console-rw --db-name=gitlabhq_production db-ci-replica-gstg

# Registry Database
$ tsh db login --db-user=console-rw --db-name=gitlabhq_registry db-registry-replica-gstg

# Delayed Replica (DR) archive of main Database
$ tsh db login --db-user=console-rw --db-name=gitlabhq_production db-main-dr-archive-gstg

# Delayed Replica (DR) archive of CI Database
$ tsh db login --db-user=console-rw --db-name=gitlabhq_production db-ci-dr-archive-gstg

# Delayed Replica (DR) archive of registry Database
$ tsh db login --db-user=console-rw --db-name=gitlabhq_registry db-registry-dr-archive-gstg
```

5. Connect to the database.

Once logged in, you can connect and disconnect from the console as many times as needed.

```bash
# Main Database
$ tsh db connect db-main-replica-gstg

# CI Database
$ tsh db connect db-ci-replica-gstg

# Registry Database
$ tsh db connect db-registry-replica-gstg

# Delayed Replica (DR) archive of main Database
$ tsh db connect db-main-dr-archive-gstg

# Delayed Replica (DR) archive of CI Database
$ tsh db connect db-ci-dr-archive-gstg

# Delayed Replica (DR) archive of registry Database
$ tsh db connect db-registry-dr-archive-gstg
```

#### Production

1. Authenticate to the Teleport instance. This command opens Okta in a browser window:

```bash
$ tsh login --proxy=production.teleport.gitlab.net
```

2. Request approval for the database role that you need.

Production (`gprd`) `main` and `CI` database roles:

- Read-only:  `prod-database-ro`
- Read-Write: `prod-database-rw`

Production (`gprd`) `registry` database roles:

- Read-only:  `prod-database-registry-ro`
- Read-Write: `prod-database-registry-rw`

```bash
$ tsh login --proxy=production.teleport.gitlab.net --request-roles=prod-database-ro --request-reason="GitLab Issue URL or ZenDesk Ticket URL"
```

This command will pause while it waits for the reviewer to approve the request.
It may appear to hang, but it is waiting for someone to approve it.
The command will return as soon as the request is approved, denied, or expires.

If the command is stopped or times out, but the request is approved, you do not need to request another approval.
Simply login and provide the approved request ID (output by the previous command, or find it in the web interface).

3. Login with the approved request ID.

The request ID is shown in the output of `tsh login` when making the initial request, and can also be found attached to
your request notification in [#teleport-requests](https://gitlab.enterprise.slack.com/archives/C06Q2JK3YPM).

```bash
$ tsh login --request-id=<request-id>
```

4. Login to the database.

Once an approval is issued, the next step is to log in to the database.
The database name at the end of the line refers to the database host that Teleport is pointing to (which you can see with `tsh db ls`).

```bash
# Main Database
$ tsh db login --db-user=console-ro --db-name=gitlabhq_production db-main-replica-gprd

# CI Database
$ tsh db login --db-user=console-ro --db-name=gitlabhq_production db-ci-replica-gprd

# Registry Database
$ tsh db login --db-user=console-ro --db-name=gitlabhq_registry db-registry-replica-gprd

# Delayed Replica (DR) archive of main Database
$ tsh db login --db-user=console-ro --db-name=gitlabhq_production db-main-dr-archive-gprd

# Delayed Replica (DR) archive of CI Database
$ tsh db login --db-user=console-ro --db-name=gitlabhq_production db-ci-dr-archive-gprd

# Delayed Replica (DR) archive of registry Database
$ tsh db login --db-user=console-ro --db-name=gitlabhq_registry db-registry-dr-archive-gprd
```

5. Connect to the database.

Once logged in, you can connect and disconnect from the console as many times as needed.

```bash
# Main Database
tsh db connect db-main-replica-gprd

# CI Database
tsh db connect db-ci-replica-gprd

# Registry Database
tsh db connect db-registry-replica-gprd

# Delayed Replica (DR) archive of main Database
tsh db connect db-main-dr-archive-gprd

# Delayed Replica (DR) archive of CI Database
tsh db connect db-ci-dr-archive-gprd

# Delayed Replica (DR) archive of registry Database
tsh db connect db-registry-dr-archive-gprd
```

#### Request Superuser Privileges (DBREs Only)

The `database-admin` role gives admin access to any database.
This role is only meant to be used by DBREs (and SREs in case of incidents).

Submit an access request as follows.

```bash
$ tsh login --proxy=production.teleport.gitlab.net --request-roles=database-admin --request-reason="GitLab Issue URL or ZenDesk Ticket URL"
$ tsh login --request-id=<request-id>
```

## Access Approval

Approvers will get your request via an automated notification in the
[#teleport-requests](https://gitlab.enterprise.slack.com/archives/C06Q2JK3YPM) Slack channel.
If you have additional context, or need to expedite an approval, please comment as a thread under that message.
If the request is urgent, you can ping `@sre-oncall`, but to spread out the workload,
please try to allow some time for others to review first if possible.
If the approval request **does not show up** in [#teleport-requests](https://gitlab.enterprise.slack.com/archives/C06Q2JK3YPM),
feel free to ask someone in that channel to take a look at your request, and provide the request ID.

Approvers will review the issue URL in the request.
If Rails Console access seems like a reasonable step to address that issue, they will approve it.

## Support

If you have any issues using Teleport, or the approval process,
please ask the [Foundations team](https://gitlab.enterprise.slack.com/archives/C0313V3L5T6)
or in the [#infrastructure-lounge](https://gitlab.enterprise.slack.com/archives/CB3LSMEJV) Slack channel.

Note: If you need more time, you can renew your role access before or after expiration using the same method as the initial request.

## Troubleshooting

### Debug

If you have issues connecting, try using the `--debug` flag to display more verbose information.

### `psql: error: could not connect to server: Connection refused Is the server running on host "localhost" (::1) and accepting TCP/IP connections on port X`

This is possibly because the local `psql` client is overriding the user and database name.
It can be resolved by running this more explicit command.

```bash
$ tsh db connect --db-user=console-ro --db-name=gitlabhq_production <database_name>
```

For example:

```bash
$ tsh db connect --db-user=console-ro --db-name=gitlabhq_production db-main-replica-gstg
```

### `psql: error: SSL SYSCALL error: Undefined error: 0 ERROR: signal: segmentation fault`

If you encounter the error, it is probably because you have `postgresql` installed via
[`asdf`](https://asdf-vm.com/) or[`mise`](https://github.com/jdx/mise). To solve it:

1. Install `postgresql` via [homebrew](https://brew.sh), if not already installed:

```bash
$ brew install postgresql@14
```

2. Run `brew --prefix` to obtain the path to the `psql` binary installed via `homebrew`:

```bash
$ $(brew --prefix postgresql@14)/bin/psql
```

3. Run `tsh db config --format=cmd <database_name>` to get the full `tsh` command, for example:

```bash
$ tsh db config --format=cmd db-customersdot-gstg

~/.asdf/shims/psql "postgres://teleport-cloudsql%40gitlab-subscriptions-staging.iam@production.teleport.gitlab.net..."
```

4. Replace the `~/.asdf/shims/psql` or `~/.local/share/mise/installs/postgres/13.9/bin/psql` if using `mise` path from
   the output of the full `tsh` command obtained in step 3 above with the path to the `psql` binary installed via `homebrew`:

```bash
$ $(brew --prefix postgresql@14)/bin/psql "postgres://teleport-cloudsql%40gitlab-subscriptions-staging.iam@production.teleport.gitlab.net:443/CustomersDot_stg?sslrootcert=/Users/<username>/.tsh/keys/production.teleport.gitlab.net/cas/production.teleport.gitlab.net.pem&sslcert=/Users/<username>/.tsh/keys/production.teleport.gitlab.net/<username>@gitlab.com-db/production.teleport.gitlab.net/db-customersdot-gstg-x509.pem&sslkey=/Users/<username>/.tsh/keys/production.teleport.gitlab.net/<username>@gitlab.com&sslmode=verify-full"
```

### `psql: error: sslmode value "verify-full" invalid when SSL support is not compiled in`

`tsh db` is a wrapper over `psql` and this likely means that your installed psql version was not configured with OpenSSL options.
You can consider taking steps like [this blog post](https://dev.to/jbranchaud/reinstall-postgresql-with-openssl-using-asdf-cmj)
if `psql` was installed via `asdf`. Ideally, use the Homebrew installed `psql` version.

### `failed to add one or more keys to the agent`

If you encounter the error

```
ERROR: failed to add one or more keys to the agent.
agent: failure, agent: failure
```

Try running the same command and passing in the flag `--add-keys-to-agent=no`

```bash
$ tsh login --add-keys-to-agent=no --proxy=production.teleport.gitlab.net
```

There is an open issue about [this](https://github.com/gravitational/teleport/issues/22326)
