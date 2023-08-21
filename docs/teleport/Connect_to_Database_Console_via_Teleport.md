# How to connect to a Database console using Teleport

## Background info about [Teleport](https://goteleport.com/teleport/docs/)

Database consoles in Staging/Production are accessed via Gravitational [Teleport](https://goteleport.com/teleport/docs/). Our legacy Database consoles (using the console servers) are in the process of being removed for most use cases.

- The main reasons for this change are security and compliance: With Teleport we'll have fully flexible, on-demand, and audited access to our Database consoles and to some other terminal/CLI tools, like `kubectl`, [Rails Console](Connect_to_Rails_Console_via_Teleport.md), and more.
- Teleport's goal is to provide a Unified Access Plane for all of our infrastructure. [Here](https://goteleport.com/teleport/docs/#why-use-teleport) you can find some of the most popular use cases for Teleport.
- We evaluated Teleport thoroughly (see this [issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11568)) and found it to comply with most of our infrastructure access requirements, unlike some of its competitors ([Okta-ASA](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/12042), [Hashicorp Boundary](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11666) and others).

## Access Requests

Before you start using Teleport, you must be assigned the app in Okta.  This should be a part of your role's baseline group assignment. In most cases there should be no additional action required to gain access to the services appropriate to your role. If your onboarding is complete and you still do not have access to the Teleport app in Okta, open an [access request](https://about.gitlab.com/handbook/business-technology/team-member-enablement/onboarding-access-requests/access-requests/) and follow the appropriate approval methods.

## How to use Teleport to connect to Database console

You need the Teleport CLI client ([tsh](https://goteleport.com/teleport/docs/cli-docs/#tsh)) to connect to a Database console.

### Installing tsh

On MacOS, it is as simple as running:

```shell
brew install teleport
```

However, the database console requires `psql` so if it is not already installed on your machine, you'll also have to run:

```shell
brew install postgres
```

Linux install instructions are [also available on the Teleport site](https://goteleport.com/docs/installation/#linux)

### Accessing the Database console via Teleport

1. Authenticate to the Teleport server
2. Unless using read only access in staging, request approval for the database role that you need
3. Log in to the database with the appropriate database user
4. Connect the database console

The access will be temporary (`12h` max) and can be approved by any SRE or Reliability Manager.  The `@sre-oncall` can help if it's urgent, but if you can wait it is considerate to spread the load out by asking the wider SRE team in `#infrastructure-lounge`. Access can be extended before or after expiration using the same process.

There are two Teleport cluster/servers:

- <https://staging.teleport.gitlab.net/> for staging
- <https://production.teleport.gitlab.net/> for production

##### Staging

1. Authenticate to the Teleport proxy/server. This command opens Okta in a browser window:

```shell
tsh login --proxy=staging.teleport.gitlab.net
```

2. Request approval for the database role that you need

> Note: The `database-ro-gstg` role in the `gstg` environment does not require a request or approval, so you can skip the next step. Use the `database-ro-gstg` role unless you know for sure that you need something else. For Package Team members, they additionaly have `database-registry-ro-gstg` role in the `gstg`, which gives them access to registry database without approval.

If you need to request a role which includes elevated permissions for the Database console. Request any of the following roles:

Staging `main` and `CI` database roles:

- `database-ro-gstg`
- `database-rw-gstg`

Staging `registry` database roles:

- `database-registry-ro-gstg`
- `database-registry-rw-gstg`

```shell
tsh login --proxy=staging.teleport.gitlab.net --request-roles=database-ro-gstg --request-reason="Issue-URL or explanation"
```

3. Login with the approved request ID

If approval is required and the above command is stopped or times out, but the request is approved, you don't need to request another approval. Instead, provide the approved request ID (output by the previous command, or find it in the web interface):

```shell
tsh login --request-id=<request-id>
```

 3. Login to the database

Once an approval (if required) is issued, the next step is to log in to the database. The database name at the end of the line refers to the database host that Teleport is pointing to (which you can see with `tsh db ls`):

```shell
# Main Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_production db-main-replica-gstg

# CI Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_production db-ci-replica-gstg

# Registry Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_registry db-registry-replica-gstg

# Delayed Replica (DR) archive of main Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_production db-main-dr-archive-gstg

# Delayed Replica (DR) archive of CI Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_production db-ci-dr-archive-gstg

# Delayed Replica (DR) archive of registry Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_registry db-registry-dr-archive-gstg
```

4. Connect to the database

Once logged in, you can connect and disconnect from the console as many times as needed.

> Tip: use the `tsh status` command to show which logins you are currently approved for.

```shell
# Main Database:
tsh db connect db-main-replica-gstg

# CI Database:
tsh db connect db-ci-replica-gstg

# Registry Database:
tsh db connect db-registry-replica-gstg

# Delayed Replica (DR) archive of main Database:
tsh db connect db-main-dr-archive-gstg

# Delayed Replica (DR) archive of CI Database:
tsh db connect db-ci-dr-archive-gstg

# Delayed Replica (DR) archive of registry Database:
tsh db connect db-registry-dr-archive-gstg
```

##### Production

1. Authenticate to the Teleport proxy/server. This command opens Okta in a browser window:

```shell
tsh login --proxy=production.teleport.gitlab.net
```

2. Request approval for the database role that you need

Production `main` and `CI` database roles:

- `database-ro-gprd`
- `database-rw-gprd`

Production `registry` database roles:

- `database-registry-ro-gprd`
- `database-registry-rw-gprd`

```shell
tsh login --proxy=production.teleport.gitlab.net --request-roles=database-ro-gprd --request-reason="Issue-URL or explanation"
```

3. Login with the approved request ID

If the command is stopped or times out, but the request is approved, you don't need to request another approval.  Simply login and provide the approved request ID (output by the previous command, or find it in the web interface):

```shell
tsh login --request-id=<request-id>
```

The request ID is shown in the output of `tsh login` when making the initial request, and can also be found attached to your request notification in `#infrastructure-lounge`.

4. Login to the database

Once an approval is issued, the next step is to log in to the database. The database name at the end of the line refers to the database host that Teleport is pointing to (which you can see with `tsh db ls`):

For the Main Database:

```shell
# Main Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_production db-main-replica-gprd

# CI Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_production db-ci-replica-gprd

# Registry Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_registry db-registry-replica-gprd

# Delayed Replica (DR) archive of main Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_production db-main-dr-archive-gprd

# Delayed Replica (DR) archive of CI Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_production db-ci-dr-archive-gprd

# Delayed Replica (DR) archive of registry Database:
tsh db login --db-user=console-ro --db-name=gitlabhq_registry db-registry-dr-archive-gprd
```

4. Connect to the database

Once logged in, you can connect and disconnect from the console as many times as needed.

> Tip: use the `tsh status` command to show which logins you are currently approved for.

```shell
# Main Database:
tsh db connect db-main-replica-gprd

# CI Database:
tsh db connect db-ci-replica-gprd

# Registry Database:
tsh db connect db-registry-replica-gprd

# Delayed Replica (DR) archive of main Database:
tsh db connect db-main-dr-archive-gprd

# Delayed Replica (DR) archive of CI Database:
tsh db connect db-ci-dr-archive-gprd

# Delayed Replica (DR) archive of registry Database:
tsh db connect db-registry-dr-archive-gprd
```

#### For all databases to request superuser privileges (DBREs only)

- `database-admin`

using the following format.

```shell
tsh login --proxy=staging.teleport.gitlab.net --request-roles=database-ro-gstg --request-reason="Issue-URL or explanation"
```

This command will pause while it waits for the approver to approve the request. It may appear to hang, but it is waiting for someone to approve it. The command will return as soon as the request is approved, denied, or times out.

If the command is stopped or times out, but the request is approved, you don't need to request another approval.  Instead, login and provide the approved request ID (output by the previous command, or find it in the web interface):

```shell
tsh login --request-id=<request-id>
```

The request ID is shown in the output of `tsh login` when making the initial request, and can also be found attached to your request notification in `#infrastructure-lounge`.

> Note: These examples assume you are requesting read-only access. For read-write, simply `--request-roles=database-rw-gstg` rather than `--request-roles=database-ro-gstg`. Please default to read-only though, since we will have stricter requirements for approving read-write access.

#### Access approval

Approvers will get your request via an automated notification in the `#infrastructure-lounge` Slack channel.  If you have additional context,
or need to expedite an approval, please comment as a thread under that message.  If the request is urgent, you can ping `@sre-oncall`, but
to spread out the workload please try to allow some time for others to review first if possible. If the approval request **doesn't show up** in
`#infrastructure-lounge` feel free to ask someone in that channel to take a look at your request, and provide the request ID.

Approvers will review the issue URL in the request and if database access seems like a reasonable step to address that issue, they will approve it.

## Support

If you have any issues using Teleport, or this approval process, please ask the **Reliability team** (SREs and/or managers) in the [#production](https://gitlab.slack.com/archives/C101F3796) or [#infrastructure-lounge](https://gitlab.slack.com/archives/CB3LSMEJV) Slack channels.

> Note: If you need more time, you can renew your role access approval before or after expiration using the same method as the initial request

## More detail

The Teleport login process is a little different from other services.  With Teleport, you are not opening a network session with a server so much as requesting that the server sign your certificate and add the appropriate role permissions to it.

The `tsh login` command requests that the server validate your identity with Okta and give you a certificate which can be used as the equivalent of an SSH key.  However, in contrast to an SSH key, this certificate expires, and also contains information on which roles you are approved for.  This information is displayed at login, but can be viewed again with `tsh status`.

```text
$ tsh status
> Profile URL:        https://staging.teleport.gitlab.net:443
  Logged in as:       <username>@gitlab.com
  Cluster:            staging.teleport.gitlab.net
  Roles:              <roles>
  Logins:             <usernames (SSH)>
  Kubernetes:         enabled
  Kubernetes groups:  <k8s groups>
  Valid until:        2023-05-02 07:00:26 +1200 NZST [valid for 11h49m0s]
  Extensions:         login-ip, permit-agent-forwarding, permit-port-forwarding, permit-pty, private-key-policy
```

Note that the default certificate might not have any roles assigned, allowing you to interact with the Teleport server, and to request more roles, but does not allow connecting to any other services.

To request permission to connect to a service, you must use the `--request-roles` flag.  You can request a role after already having a valid certificate, or simply by adding the flag to your initial login. Each `--request-roles` requires a `--request-reason`. It's best to use the URL of the issue or incident that this activity relates to.

```shell
tsh login --proxy=staging.teleport.gitlab.net --request-roles=database-ro-gstg --request-reason="Issue-URL or explanation"
```

Once approved, the server will replace your loally stored certificate with an updated one, and your newly valid roles will appear in the `tsh status` output.

## Troubleshooting

### Debug

If you have issues connecting, try using the `--debug` flag to display more verbose information

### `psql: error: sslmode value "verify-full" invalid when SSL support is not compiled in`

`tsh db` is a wrapper over `psql` and this likely means that your installed psql version was not configured with OpenSSL options. You can consider taking steps like [this blog post](https://dev.to/jbranchaud/reinstall-postgresql-with-openssl-using-asdf-cmj) if psql was installed via asdf. Ideally, use the brew installed psql version.

### `failed to add one or more keys to the agent`

If you encounter the error

```
ERROR: failed to add one or more keys to the agent.
agent: failure, agent: failure
```

Try running the same command and passing in the flag `--add-keys-to-agent=no`

```
tsh login --add-keys-to-agent=no --proxy=staging.teleport.gitlab.net
```

There is an open issue about [this](https://github.com/gravitational/teleport/issues/22326)
