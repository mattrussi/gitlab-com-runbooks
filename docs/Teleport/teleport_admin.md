# Teleport Administration

This run book covers administration of the Teleport service from an infrastructure perspective.

- See the [Teleport Rails Console](Connect_to_Rails_Console_via_Teleport.md) runbook if you'd like to log in to a machine using teleport
- See the [Teleport Database Console](Connect_to_Database_Console_via_Teleport.md) runbook if you'd like to connect to a database using teleport
- See the [Teleport Approval Workflow](teleport_approval_workflow.md) runbook if you'd like to review and approve access requests

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

## Rebuilding the service

For the most part, the service can be rebuilt by using `tf destroy` and `tf apply` in the usual way.  There are a few manual steps though.

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

Once everything is up and running, the teleport server will have generated a new CA key.  The other nodes need this key in order to join the cluster.

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
