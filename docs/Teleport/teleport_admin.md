# Teleport Administration

This run book covers administration of the Teleport service from an infrastructure perspective.

- See the [Teleport Rails Console](Connect_to_Rails_Console_via_Teleport.md) runbook if you'd like to log in to a machine using teleport
- See the [Teleport Database Console](Connect_to_Database_Console_via_Teleport.md) runbook if you'd like to connect to a database using teleport
- See the [Teleport Approval Workflow](teleport_approval_workflow.md) runbook if you'd like to review and approve access requests

## Quick fix

In almost all cases, when the service is not responding, the safest and most effective fix is simply to restart either the teleport service (`sudo systemctl restart teleport`), or the entire teleport node.  The only reason not to reboot the node is that it will interrupt existing sessions, but if there is a problem establishing sessions, this won't be a problem.  We have seen a lot of cases where a restart provided a permanent fix to strange issues.  Try this first.

## Access Changes

Access is configured in the [Teleport Chef Cookbook](https://gitlab.com/gitlab-cookbooks/gitlab-teleport)

- Associations between Okta groups and Teleport roles are fairly straightforward, and can be edited in the [okta-connector.yaml.erb](https://gitlab.com/gitlab-cookbooks/gitlab-teleport/-/blob/master/templates/default/okta-connector.yaml.erb) template
- Modifications to role permissions and settings are made in the [role-* files](https://gitlab.com/gitlab-cookbooks/gitlab-teleport/-/tree/master/files/default)

## If Approvals appear to be working, but user doesn't receive the cert

We have seen this problem recently, and it appears to be a bug in the Teleport server.  The vendor is investigating. The symptom is that all parts of the process appear to work fine, but after approving the request, the user never receives a signed certificate.  The request process just hangs, waiting for it.

The workaround is simply to restart the teleport service.  Use the restart command in the next section.  So far, this has always made everything work again as expected.  The user may need to submit another request after the restart.

## Checking status on the Teleport Server

Summary from the [teleport admin docs](https://goteleport.com/docs/admin-guide/).  There is a systemd unit for teleport and the standard systemctl commands should work.

- Check the status of the server: `systemctl status teleport`
- Restart teleport on the server: `sudo systemctl restart teleport`
- Check the systemd logs: `sudo journalctl -u teleport`
- local check that things are up: `sudo tctl status`

## Rebuilding the teleport server

If you just want to rebuild the teleport server, and not the load balancers, console servers, and instance groups that are associated with it, then you just need to taint the node (`tf taint module.teleport.google_compute_instance.default[0]`) and do a targetted plan (`tf plan -target=module.teleport`) and apply (`tf apply -target=module.teleport`).

Once the node is rebuilt, all settings and certificates will have been destroyed, so you'll need to set up the [Secrets](#secrets) and [Slack integration](#slack-integration) again.

## Rebuilding the entire service

For the most part, the service can be rebuilt by using `tf destroy` and `tf apply` in the usual way. Many of the components have their lifecycle settings set to not allow destroy, so you'll have to go through the messy process of disabling them if you really want to do this.  There is a very good chance that you really don't want to do this.  Unless you are really sure that this is the only way to accomplish what you want to accomplish, you should probably just be rebuilding the teleport server itself (See the section above)

### Terraform

One of the components needs to exist before others can be created.  Run this targeted apply before the others.

```shell
tf apply -target module.gcp-tcp-lb-teleport.google_compute_forwarding_rule.default
```

After that has been run, the other parts can be targeted with.

```shell
tf plan --target module.teleport --target module.gcp-tcp-lb-teleport -target module.console-ro
tf apply --target module.teleport --target module.gcp-tcp-lb-teleport -target module.console-ro
```

### Secrets

Once everything is up and running, the teleport server will have generated a new CA key.  The other nodes need this key in order to join the cluster. Note that there is no need to do this on an existing cluster. This only applies on a new cluster, or if you have run `tf destroy` and are building the cluster again from scratch.

Get the key from the auth server:

```shell
tctl status
```

And paste it in to the `ca_pin`  field in the`gkms` teleport secrets for the environment.

```json
    "ca_pin": "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

### Chef

For some reason, when deleting these nodes, sometimes the chef client and node resources don't get automatically removed.

```shell
knife client delete console-ro-01-sv-gprd.c.gitlab-production.internal
knife node delete console-ro-01-sv-gprd.c.gitlab-production.internal
```

## Slack integration

The slack integration connects to the authentication proxy as a user, using client certificate auth.  This client certificate does not yet auto-renew. You can check the expiration date with:

```shell
devin@teleport-01-inf-gstg.c.gitlab-staging-1.internal:~$ sudo openssl x509 -enddate -noout -in /var/lib/teleport/plugins/slack/auth.crt
```

Then follow the Teleport documentation for [generating a new cert](https://goteleport.com/docs/enterprise/workflow/ssh-approval-slack/#export-the-access-plugin-certificate) (you can't yet renew the existing one, but a new one works fine)

## teleport-slack.service restarting every 10-15seconds

If slack integration certificate gets expired then `teleport-slack` service may go into infinite restart loop due to failure to connect to authentication proxy. In such cases, teleport log can provide hints:

Check `teleport` logs as follows on the teleport bastion server:

```shell
journalctl -u teleport -f
```

In such cases teleport will repeatedly log ssl Handshake failures as below:

```
Aug  2 19:15:33 teleport-01-inf-gstg teleport[772]: 2022-08-02T19:15:33Z WARN [MXTLS:1]   Handshake failed. error:[tls: failed to verify client certificate: x509: certificate has expired or is not yet valid: current time 2022-08-02T19:15:33Z is after 2022-07-27T03:58:24Z] multiplexer/tls.go:146
Aug  2 19:15:34 teleport-01-inf-gstg teleport[772]: 2022-08-02T19:15:34Z WARN [MXTLS:1]   Handshake failed. error:[tls: failed to verify client certificate: x509: certificate has expired or is not yet valid: current time 2022-08-02T19:15:34Z is after 2022-07-27T03:58:24Z] multiplexer/tls.go:146
Aug  2 19:15:35 teleport-01-inf-gstg teleport[772]: 2022-08-02T19:15:35Z WARN [MXTLS:1]   Handshake failed. error:[tls: failed to verify client certificate: x509: certificate has expired or is not yet valid: current time 2022-08-02T19:15:35Z is after 2022-07-27T03:58:24Z] multiplexer/tls.go:146
Aug  2 19:15:36 teleport-01-inf-gstg teleport[772]: 2022-08-02T19:15:36Z INFO [DB:SERVIC] Connected. addr:34.75.5.75:53528 remote-addr:34.75.5.75:3024 leaseID:105 target:teleport.gstg.gitlab.net:3024 reversetunnel/agent.go:393
```

For such cases, you can follow the steps in [Slack integration](#slack-integration) to check and renew ssl certs for teleport slack process.
