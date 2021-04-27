# Teleport Administration

This run book covers administration of the Teleport service from an infrastructure perspective. 

- See the [Teleport Rails Console](Connect_to_Rails_Console_via_Teleport.md) runbook if you'd like to log in to a machine using teleport
- See the [Teleport Approval Workflow](teleport_approval_workflow.md) runbook if you'd like to review and approve access requests

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

For some reason, when deleting these nodes, the chef client and node resources don't get automatically removed.

```shell
knife client delete console-ro-01-sv-gprd.c.gitlab-production.internal
knife node delete console-ro-01-sv-gprd.c.gitlab-production.internal
```