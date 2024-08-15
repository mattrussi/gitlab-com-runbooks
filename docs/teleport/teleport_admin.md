# Teleport Administration

**Table of Contents**

[TOC]

This run book covers administration of the Teleport service from an infrastructure perspective.

- See the [Teleport Rails Console](Connect_to_Rails_Console_via_Teleport.md) runbook if you'd like to log in to a machine using teleport.
- See the [Teleport Database Console](Connect_to_Database_Console_via_Teleport.md) runbook if you'd like to connect to a database using teleport.
- See the [Teleport Approval Workflow](teleport_approval_workflow.md) runbook if you'd like to review and approve access requests.
- See the [Teleport Disaster Recovery](teleport_disaster_recovery.md) runbook if you'd like to know about the DR operations for Teleport.

## Infrastructure Setup

We run two Teleport clusters. The production cluster is used for managing all GitLab's infrastructure resources (VMs, databases, etc.).
The staging cluster is used for testing new changes, major upgrades, disaster recovery process, etc.
Users only need to know about and use the production Teleport cluster available at <https://production.teleport.gitlab.net>.

The production Teleport cluster currently runs on `ops-central` GKE cluster in `us-central1`
while the staging one runs on `ops-gitlab-gke` GKE cluster in `us-east1`.
We run the production Teleport cluster on a different region than the region we run our production infrastruture,
so we can still access our infrastructure in case there is a region failure in our production region (`us-east1`).

The infra-as-code for these Teleport clusters can be found in the following locations:

- [teleport-production](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/main/environments/teleport-production)
- [teleport-staging](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/main/environments/teleport-staging)

### Architecture

Very high level, Teleport has two major components: Teleport cluster and Teleport agents.
Teleport agents are processes that run on VMs or Kubernetes clusters and register resources with a Teleport cluster.

At GitLab, we run the Teleport agent on our VMs using the
[gitlab-teleport](https://gitlab.com/gitlab-cookbooks/gitlab-teleport) cookbook and on our GKE clusters using the `teleport-agent`
Helm [chart](https://goteleport.com/docs/reference/helm-reference/teleport-kube-agent/) and
[release](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/teleport-agent).
We also run a Teleport cluster using the `teleport-cluster`
Helm [chart](https://goteleport.com/docs/reference/helm-reference/teleport-cluster/) and
[release](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/teleport-cluster).

The agents running VMs register the VMs they are running on as servers.
The agents running on Kubernetes clsuters register the Kubernetes clusters they are running on
The Kubernetes management with Teleport is disabled at the moment since our license does not include this feature.
The Teleport agents running on Kubernetes clusters also act as a proxy for registering our Postgres databases.

The Teleport cluster is comprised of multiple components.

- **Teleport Auth Service**
  - The auth service acts as a certificate authority (CA) for the cluster.
  - It issues [certificates](https://goteleport.com/docs/architecture/authentication/)
    for clients and nodes, collects the audit information, and stores it in the audit log.
  - The auth service is run in *high-availability* mode in our GKE clusters.
  - The auth service can be configured via [`tctl`](https://goteleport.com/docs/reference/cli/tctl/) command line tool.
- **Teleport Proxy Service**
  - The [proxy](https://goteleport.com/docs/architecture/proxy/) is the only service in a cluster visible to the outside world.
  - All user connections for all supported protocols go through the proxy.
  - The proxy also serves the Web UI and allows remote nodes to establish reverse tunnels.
  - The proxy service is also run in *high-availability* mode in our GKE clusters.
- **Teleport Kubernetes Operator**
  - The [Teleport Kubernetes Operator](https://goteleport.com/docs/management/dynamic-resources/teleport-operator/)
    provides a way for Kubernetes users to manage some Teleport resources through Kubernetes,
    following the [Operator Pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).
- **Teleport Slack Plugin**
  - Teleport's Slack integration is used for notifying individuals and
    [#teleport-requests](https://gitlab.enterprise.slack.com/archives/C06Q2JK3YPM) channel.
- **Teleport Event-Handler Plugin**
  - Teleport's event-handler plugins allows securely sending audit events to a Fluentd instance for further processing by SIEM systems.

### Authentication

[Certificate-based authentication](https://goteleport.com/how-it-works/certificate-based-authentication-ssh-kubernetes/)
is the most secure form of authentication.
Teleport supports all the necessary certificate management operations to enable certificate-based authentication at scale.
You can read more about authentication in Teleport [here](https://goteleport.com/docs/architecture/authentication/).

### Authorization

Teleport uses *Role-Based Access Control* (RBAC) model.
We define roles and each role specifies what is allowed and what is not allowed.
You can read more about authoriztion in Teleport [here](https://goteleport.com/docs/architecture/authorization/).

## Secrets

We use the *Google Cloud Key Management Service* (KMS) to store and handle Teleport certificate authorities.

> Teleport generates private key material for its internal Certificate Authorities (CAs) during the first Auth Server's initial startup.
> These CAs are used to sign all certificates issued to clients and hosts in the Teleport cluster.
> When configured to use Google Cloud KMS,
> all private key material for these CAs will be generated, stored, and used for signing inside of Google Cloud KMS.
> Instead of the actual private key, Teleport will only store the ID of the KMS key.
> In short, private key material will never leave Google Cloud KMS.

Please refer to this [guide](https://goteleport.com/docs/choose-an-edition/teleport-enterprise/gcp-kms/)
for more information on storing Teleport private keys in Google Cloud KMS.

We create a [Key Ring](https://cloud.google.com/kms/docs/resource-hierarchy#key_rings) and a *CryptoKey* for Teleport CA
in this [file](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/modules/teleport-project/kms.tf).
We then reference this key when installing the `teleport-cluster` Helm chart
[here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/01976afc89a7f3b86e58751a13aad6d0c8d25572/releases/teleport-cluster/ops-central-production.yaml.gotmpl#L30)

We do not manage any certificate authority and private keys inside the cluster. They are all stored in and managed by KMS.

> To help guard against data corruption and to verify that data can be decrypted successfully,
> Cloud KMS periodically scans and backs up all key material and metadata.

Please refer to this [deep dive document](https://cloud.google.com/docs/security/key-management-deep-dive)
on Google Cloud KMS and automatic backups.

## Database Management

The PosgreSQL databases are registered with the Teleport instance by
[Teleport agents](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/teleport-agent)
running on our regional Kubernetes clusters.

The certificates (
  [gprd](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/7b160f1ea422ae44515ba46830347565c19ca708/releases/teleport-agent/values-secrets/gprd.yaml.gotmpl#L12) and
  [gstg](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/7b160f1ea422ae44515ba46830347565c19ca708/releases/teleport-agent/values-secrets/gstg.yaml.gotmpl#L12
) used by
[teleport-agent](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/teleport-agent)
running on Kubernetes clusters should match the PostgreSQL server certificate located at `/var/opt/gitlab/postgresql/server.crt`.

Furthermore, the CA file found at `/var/opt/gitlab/postgresql/cacert` on each Patroni or PostgreSQL node should correspond to
the certificate authority used by the Teleport instance with which those databases are registered.
This file is written by the `gitlab-patroni::postgres` recipe which is imported by the `gitlab-patroni::default` recipe.
This recipe retrives the content of CA file from `gs://gitlab-<env>-secrets/gitlab-patroni/gstg.enc`.

If you move databases to a different Teleport instance and update this CA file, please remember to
run the `select pg_reload_conf();` command from the `gitlab-psql` shell on each node to reload the update CA.

Here is an example [CR](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18355) for updating the CA file.

## Role and Access Management

Teleport [roles](https://goteleport.com/docs/access-controls/reference/) and permissions are defined in
[`roles_*.tf`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/main/environments/teleport-production) files.
If you add a new role, you also need to add it to
[`roles.tf`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/teleport-production/roles.tf) file.

The association between Okta groups and Teleport roles are configured in
[`groups.tf`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/teleport-production/groups.tf) file.

## Checking Status of Teleport

All the services comprise a Teleport cluster are stateless.

- All certificates and keys are stored in
  [KMS](https://console.cloud.google.com/security/kms/keyring/manage/us/gitlab-teleport-teleport-production/key?project=gitlab-teleport-production).
- The cluster internal state and audit events are stored in
  [Firestore](https://console.cloud.google.com/firestore/databases/-default-?project=gitlab-teleport-production).
- The [session recordings](https://goteleport.com/docs/architecture/session-recording/) are stored in a Cloud Storage
  [bucket](https://console.cloud.google.com/storage/browser/gl-teleport-production-teleport-sessions?project=gitlab-teleport-production).

You can check the status of the production Teleport cluster by running the following command,
after running `glsh kube use-cluster ops-central` command in a separate shell:

```
$ kubectl exec --namespace=teleport-cluster-production --stdin --tty <teleport-production-auth-pod> -- tctl status
```

<details>
<summar>example output</summary>

```
Cluster       production.teleport.gitlab.net
Version       15.4.9
host CA       never updated
user CA       never updated
db CA         never updated
db_client CA  never updated
openssh CA    never updated
jwt CA        never updated
saml_idp CA   never updated
oidc_idp CA   never updated
spiffe CA     never updated
CA pin        sha256:25869bcdc1a347668dd9a83110f96a9a7fb70c2791bf839180b3abeadded2891
```

</details>

Generally, if the pods are healthy, then the service is healthy.

## Updating Enterprise License

We use the same License for both [staging](https://staging.teleport.gitlab.net)
and [production](https://production.teleport.gitlab.net) instances teleport.

When our license is about to expire, we need to obtain a new license file and update our Teleport instances with.
Read more about the *Enterprise License file* [here](https://goteleport.com/docs/choose-an-edition/teleport-enterprise/license/).
In short, you need to login to [gitlab.teleport.sh](https://gitlab.teleport.sh) as an admin and download the new license file (`license.pem`).
You can also ask an admin user to do so and share the license file with you through a secure channel (*1Password*).

Add the new license to Vault.

```bash
# Run this command from the runbooks repo
$ glsh vault proxy

# Write the new license to Vault
$ vault login -method oidc role=admin
$ vault kv put k8s/ops-central/teleport-cluster-production/license license.pem=@license.pem
```

Grab the latest version from the output last command and update it
[here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/releases/teleport-cluster/values-secrets/ops-central-production.yaml.gotmpl?ref_type=heads#L10).

Finally restart the Teleport Auth component.

```bash
# Run this command from the runbooks repo
$ glsh kube use-cluster ops-central

# Restart the teleport auth pods
$ kubectl rollout restart deployment/teleport-production-auth --namespace=teleport-cluster-production
```

## Slack Integration

The `teleport-plugin-slack` authenticated to the Teleport cluster as a user with the name `teleport-plugin-slack`.
This user is assigned a role with the same name (`teleport-plugin-slack`).
Both of this user and it roles are created in this [file](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/releases/teleport-cluster/charts/teleport-bootstrap/templates/slack.yaml).

The `teleport-plugin-slack` user needs an identity. We generate this idendity to be valid for 1 year.
**Currently, this user identity does NOT renew automatically and we need to renew it manually once a year**.
Please follow the Teleport
[documentation](https://goteleport.com/docs/access-controls/access-request-plugins/ssh-approval-slack/#step-48-export-the-access-plugin-identity)
for temporarily creating an `impersonator` role and assign it to the `teleport-plugin-slack` user, and then generate a new identity.

## SIEM Integration

The `teleport-plugin-event-handler` is used for handling Teleport audit events and sending them to a [Fluentd](https://www.fluentd.org/) instance,
so such events can be further shipped to other systems (i.e. SIEM) for security and auditing purposes.
Read more about exporting exporting Teleport audit events [here](https://goteleport.com/docs/management/export-audit-events/).

- This plugin is installed using
  [teleport-plugin-event-handler](https://goteleport.com/docs/reference/helm-reference/teleport-plugin-event-handler/) Helm chart
  (see [this](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/releases/teleport-cluster/helmfile.yaml)).
- A user and role named `teleport-event-handler` are created via the `teleport-bootstrap` chart
  (see [this](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/releases/teleport-cluster/charts/teleport-bootstrap/templates/event-handler.yaml)).
- An impersonator role needs to be created and assigned for requesting an identity certificate for the `teleport-event-handler` user.

See this [guide](https://goteleport.com/docs/management/export-audit-events/fluentd/) or
[this](https://github.com/gravitational/teleport-plugins/tree/master/event-handler) one for further instructions.

### Export an Identity File

If you need to update or rotate the auth identity for `teleport-event-handler` user,
follow the steps below for each Teleport cluster.

<details>
<summary>Commands</summary>

```bash
$ tsh login --proxy=production.teleport.gitlab.net
$ tctl get saml/okta --with-secrets > user-saml-production.yaml

# 1. Open user-saml-production.yaml
# 2. Add `teleport-event-handler-impersonator` to your "GitLab - SRE" group roles.
tctl create -f user-saml-production.yaml

# Login again to assume the teleport-event-handler-impersonator role
$ tsh logout
$ tsh login --proxy=production.teleport.gitlab.net

# Request and sign an identity certificate for the teleport-event-handler user
$ tctl auth sign --user=teleport-event-handler --ttl=8760h --out=auth-id-production

# Write the secret to Vault
$ vault login -method oidc
$ vault kv put k8s/ops-central/teleport-cluster-production/event-handler auth_id=@auth-id-production
$ vault kv get -format=json k8s/ops-central/teleport-cluster-production/event-handler | jq '.data.metadata.version'
```

</details>

Get the lastest secret version from Vault and update the `teleport-cluster` release with it
[here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/a2aa14a8676e6a839e62ad90350f438e13cca58e/releases/teleport-cluster/values-secrets/ops-central-production.yaml.gotmpl#L36)

### Configuring mTLS Communication

The `teleport-plugin-event-handler` requires *Mutual TLS* connection be enabled on `fluentd` instance for security purposes.
The certificate authority, server key and certificate, and client key and certificate are stored in Vault at
`k8s/ops-gitlab-gke/teleport-cluster-staging/fluentd-certs` and `k8s/ops-central/teleport-cluster-production/fluentd-certs`.

For renewing the certificates, create the following files in a directory.

<details>
<summary>openssl.conf</summary>

```conf
[req]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[req_distinguished_name]
countryName            = Country Name (2 letter code)
stateOrProvinceName    = State or Province Name
localityName           = Locality Name
0.organizationName     = Organization Name
organizationalUnitName = Organizational Unit Name
commonName             = Common Name
emailAddress           = Email Address

countryName_default            =
stateOrProvinceName_default    =
localityName_default           =
0.organizationName_default     = GitLab Inc.
organizationalUnitName_default = Teleport
commonName_default             = localhost
emailAddress_default           =

[v3_ca]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical, CA:true, pathlen: 0
keyUsage               = critical, cRLSign, keyCertSign

[client_cert]
basicConstraints       = CA:FALSE
nsCertType             = client, email
nsComment              = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
keyUsage               = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage       = clientAuth, emailProtection

[crl_ext]
authorityKeyIdentifier = keyid:always

[ocsp]
basicConstraints       = CA:FALSE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
keyUsage               = critical, digitalSignature
extendedKeyUsage       = critical, OCSPSigning

[staging_server_cert]
basicConstraints       = CA:FALSE
nsCertType             = server
nsComment              = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage               = critical, digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth
subjectAltName         = @staging_alt_names

[staging_alt_names]
DNS.0 = teleport-staging-fluentd-headless.teleport-cluster-staging.svc.cluster.local
DNS.1 = *.teleport-staging-fluentd-headless.teleport-cluster-staging.svc.cluster.local
DNS.2 = teleport-staging-fluentd-aggregator.teleport-cluster-staging.svc.cluster.local
DNS.3 = *.teleport-staging-fluentd-aggregator.teleport-cluster-staging.svc.cluster.local

[production_server_cert]
basicConstraints       = CA:FALSE
nsCertType             = server
nsComment              = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage               = critical, digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth
subjectAltName         = @production_alt_names

[production_alt_names]
DNS.0 = teleport-production-fluentd-headless.teleport-cluster-production.svc.cluster.local
DNS.1 = *.teleport-production-fluentd-headless.teleport-cluster-production.svc.cluster.local
DNS.2 = teleport-production-fluentd-aggregator.teleport-cluster-production.svc.cluster.local
DNS.3 = *.teleport-production-fluentd-aggregator.teleport-cluster-production.svc.cluster.local
```

</details>

<details>
<summary>Makefile</summary>

```makefile
key_len        := 4096
staging_dir    := staging
production_dir := production

.PHONY: gen-staging
gen-staging:
  mkdir -p $(staging_dir)
  rm -f $(staging_dir)/*

  openssl genrsa -out $(staging_dir)/ca.key $(key_len)
  chmod 444 $(staging_dir)/ca.key
  openssl req -config openssl.conf -key $(staging_dir)/ca.key -new -x509 -days 3650 -sha256 -extensions v3_ca -subj "/CN=ca" -out $(staging_dir)/ca.crt

  openssl genrsa -out $(staging_dir)/client.key $(key_len)
  chmod 444 $(staging_dir)/client.key
  openssl req -config openssl.conf -subj "/CN=teleport-event-handler" -key $(staging_dir)/client.key -new -out $(staging_dir)/client.csr
  openssl x509 -req -in $(staging_dir)/client.csr -CA $(staging_dir)/ca.crt -CAkey $(staging_dir)/ca.key -CAcreateserial -days 365 -out $(staging_dir)/client.crt -extfile openssl.conf -extensions client_cert

  openssl genrsa -out $(staging_dir)/server.key $(key_len)
  chmod 444 $(staging_dir)/server.key
  openssl req -config openssl.conf -subj "/CN=fluentd-aggregator" -key $(staging_dir)/server.key -new -out $(staging_dir)/server.csr
  openssl x509 -req -in $(staging_dir)/server.csr -CA $(staging_dir)/ca.crt -CAkey $(staging_dir)/ca.key -CAcreateserial -days 365 -out $(staging_dir)/server.crt -extfile openssl.conf -extensions staging_server_cert

.PHONY: gen-production
gen-production:
  mkdir -p $(production_dir)
  rm -f $(production_dir)/*

  openssl genrsa -out $(production_dir)/ca.key $(key_len)
  chmod 444 $(production_dir)/ca.key
  openssl req -config openssl.conf -key $(production_dir)/ca.key -new -x509 -days 3650 -sha256 -extensions v3_ca -subj "/CN=ca" -out $(production_dir)/ca.crt

  openssl genrsa -out $(production_dir)/client.key $(key_len)
  chmod 444 $(production_dir)/client.key
  openssl req -config openssl.conf -subj "/CN=teleport-event-handler" -key $(production_dir)/client.key -new -out $(production_dir)/client.csr
  openssl x509 -req -in $(production_dir)/client.csr -CA $(production_dir)/ca.crt -CAkey $(production_dir)/ca.key -CAcreateserial -days 365 -out $(production_dir)/client.crt -extfile openssl.conf -extensions client_cert

  openssl genrsa -out $(production_dir)/server.key $(key_len)
  chmod 444 $(production_dir)/server.key
  openssl req -config openssl.conf -subj "/CN=fluentd-aggregator" -key $(production_dir)/server.key -new -out $(production_dir)/server.csr
  openssl x509 -req -in $(production_dir)/server.csr -CA $(production_dir)/ca.crt -CAkey $(production_dir)/ca.key -CAcreateserial -days 365 -out $(production_dir)/server.crt -extfile openssl.conf -extensions production_server_cert
```

</details>

Run the `make gen-production` command for generating certificates for the `teleport-production` cluster.

and the `make gen-production` command for the `teleport-production` cluster.
Next, update the Vault secret as follows.

```bash
$ vault login -method oidc
$ vault kv put k8s/ops-central/teleport-cluster-production/fluentd-certs \
    ca.crt="$(cat ca.crt)" \
    server.crt="$(cat server.crt)" \
    server.key="$(cat server.key)" \
    client.crt="$(cat client.crt)" \
    client.key="$(cat client.key)"
```

Finally, get the latest secret version from the Vault and update the `teleport-cluster` release for
staging [here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/99d1cf9ab9c96a25b68148fe98ddb4b3c62018ee/releases/teleport-cluster/values-secrets/ops-staging.yaml.gotmpl#L38)
and production [here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/99d1cf9ab9c96a25b68148fe98ddb4b3c62018ee/releases/teleport-cluster/values-secrets/ops-central-production.yaml.gotmpl#L38).

### Google Cloud Pub/Sub Configurations

Fluentd uses [fluent-plugin-gcloud-pubsub-custom](https://github.com/mia-0032/fluent-plugin-gcloud-pubsub-custom) gem
for sending the audit events to the following Google Cloud Pub/Sub topics:

- `projects/gitlab-teleport-staging/topics/teleport-staging-events`
- `projects/gitlab-teleport-production/topics/teleport-production-events`

We use a custom-built OCI (Docker) image with the `fluent-plugin-gcloud-pubsub-custom` gem baked into the image.
You can update/modify this image [here](https://gitlab.com/gitlab-com/gl-infra/oci-images/-/tree/main/fluentd/bitnami-ext).

We use [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
for authenticating to Google Cloud. The *Workload Identity* is configured
[here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/modules/teleport-cluster/service-account.tf)
and the required *Roles* are configured
[here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/modules/teleport-project/pubsub.tf).
