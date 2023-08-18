# Teleport Administration

This run book covers administration of the Teleport service from an infrastructure perspective.

- See the [Teleport Rails Console](Connect_to_Rails_Console_via_Teleport.md) runbook if you'd like to log in to a machine using teleport
- See the [Teleport Database Console](Connect_to_Database_Console_via_Teleport.md) runbook if you'd like to connect to a database using teleport
- See the [Teleport Approval Workflow](teleport_approval_workflow.md) runbook if you'd like to review and approve access requests

## Access Changes

Access is configured at:

- Staging [teleport-staging in `config-mgmt`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/teleport-staging)
- Production [teleport-production in `config-mgmt`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments/teleport-staging)

Associations between Okta groups and Teleport roles are fairly straightforward, and can be edited in the [groups.tf](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/environments/teleport-production/groups.tf) file.

Modifications to role permissions and settings are made in the `roles-*.tf` files.

## Checking status of the Teleport Server

Teleport runs in two GKE clusters, both in the `gitlab-ops` GCP project:

- `https://staging.teleport.gitlab.net/` in GKE cluster `ops-gitlab-gke` (us-east1)
- `https://production.teleport.gitlab.net/` in GKE cluster `ops-central` (us-central1)

The service in Kubernetes is composed of 2 Deployments (`auth` and `proxy`) that are stateless, all data (certificates, DB, sessions, etc) is stored in external GCP resources (KMS, Firestore, GCS) that reside in their own isolated GCP projects (`gitlab-teleport-*`).

1. Connect to the GKE cluster
2. Check Deployments in the namespace `teleport-cluster-<env>`
3. Get a console into one of the `auth` pods, `teleport` container
4. Execute `tctl status`

This will print the version and some CA info, meaning the cluster is funcioning.

```shell
root@teleport-staging-auth-75b8dc9696-rc856:/# tctl status
Cluster      staging.teleport.gitlab.net
Version      12.2.5
host CA      never updated
user CA      never updated
db CA        never updated
openssh CA   never updated
jwt CA       never updated
saml_idp CA  never updated
CA pin       sha256:<sha>
```

Generally, if the pods are healthy, then the service is healthy.

## Secrets

All cluster cert secrets are stored in KMS, we don't manage any private keys (including CA).

## Slack integration

The slack integration connects to the authentication proxy as a user, using client identity auth.  This client identity does not yet auto-renew.

Follow the Teleport documentation for [generating a new identity](https://goteleport.com/docs/access-controls/access-request-plugins/ssh-approval-slack/#export-the-access-plugin-certificate).

## Event Handler Plugin

`teleport-event-handler` plugin is used for handling Teleport audit events and sending them to a [Fluentd](https://www.fluentd.org/) instance,
so such events can be further shipped to other systems (i.e. SIEM) for security and auditing purposes.
Read me about exporting exporting Teleport audit events [here](https://goteleport.com/docs/management/export-audit-events/).

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

#### Staging

```bash
$ tsh login --proxy=staging.teleport.gitlab.net
$ tctl get saml/okta --with-secrets > user-saml-staging.yaml

# TODO:
#   1. Open user-saml-staging.yaml
#   2. Add `teleport-event-handler-impersonator` to your "GitLab - SRE" group roles.
tctl create -f user-saml-staging.yaml

# Login again to assume the teleport-event-handler-impersonator role
$ tsh logout
$ tsh login --proxy=staging.teleport.gitlab.net

# Request and sign an identity certificate for the teleport-event-handler user
$ tctl auth sign --user=teleport-event-handler --ttl=8760h --out=auth-id-staging

# Write the secret to Vault
$ vault login -method oidc role=admin
$ vault kv put k8s/ops-gitlab-gke/teleport-cluster-staging/event-handler auth_id="$(cat auth-id-staging)"
$ vault kv get -format=json k8s/ops-gitlab-gke/teleport-cluster-staging/event-handler | jq '.data.metadata.version'
```

Get the lastest secret version from Vault and update the `teleport-cluster` release with it
[here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/a2aa14a8676e6a839e62ad90350f438e13cca58e/releases/teleport-cluster/values-secrets/ops-staging.yaml.gotmpl#L36)

#### Production

```bash
$ tsh login --proxy=production.teleport.gitlab.net
$ tctl get saml/okta --with-secrets > user-saml-production.yaml

# TODO:
#   1. Open user-saml-production.yaml
#   2. Add `teleport-event-handler-impersonator` to your "GitLab - SRE" group roles.
tctl create -f user-saml-production.yaml

# Login again to assume the teleport-event-handler-impersonator role
$ tsh logout
$ tsh login --proxy=production.teleport.gitlab.net

# Request and sign an identity certificate for the teleport-event-handler user
$ tctl auth sign --user=teleport-event-handler --ttl=8760h --out=auth-id-production

# Write the secret to Vault
$ vault login -method oidc role=admin
$ vault kv put k8s/ops-central/teleport-cluster-production/event-handler auth_id="$(cat auth-id-production)"
$ vault kv get -format=json k8s/ops-central/teleport-cluster-production/event-handler | jq '.data.metadata.version'
```

Get the lastest secret version from Vault and update the `teleport-cluster` release with it
[here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/a2aa14a8676e6a839e62ad90350f438e13cca58e/releases/teleport-cluster/values-secrets/ops-central-production.yaml.gotmpl#L36)

### Configuring mTLS Communication

The `teleport-event-handler` plugin requires Mutual TLS connection be enabled on `fluentd` instance for security purposes.
The certificate authority, server key and certificate, and client key and certificate are stored in Vault at
`k8s/ops-gitlab-gke/teleport-cluster-staging/fluentd-certs` and `k8s/ops-gitlab-gke/teleport-cluster-production/fluentd-certs`.

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

#### Staging

Run the `make gen-staging` command for generating certificates for the `teleport-staging` cluster.
Next, update the Vault secret as follows.

```bash
$ vault login -method oidc role=admin
$ vault kv put k8s/ops-gitlab-gke/teleport-cluster-staging/fluentd-certs \
    ca.crt="$(cat ca.crt)" \
    server.crt="$(cat server.crt)" \
    server.key="$(cat server.key)" \
    client.crt="$(cat client.crt)" \
    client.key="$(cat client.key)"
```

Finally, get the latest secret version from Vault and update the `teleport-cluster` release with it
[here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/teleport-cluster/values-secrets)

#### Production

Run the `make gen-production` command for generating certificates for the `teleport-production` cluster.

and the `make gen-production` command for the `teleport-production` cluster.
Next, update the Vault secret as follows.

```bash
$ vault login -method oidc role=admin
$ vault kv put k8s/ops-central/teleport-cluster-production/fluentd-certs \
    ca.crt="$(cat ca.crt)" \
    server.crt="$(cat server.crt)" \
    server.key="$(cat server.key)" \
    client.crt="$(cat client.crt)" \
    client.key="$(cat client.key)"
```

Finally, get the latest secret version from Vault and update the `teleport-cluster` release with it
[here]()

### Google Cloud Pub/Sub Configurations

Fluentd uses [fluent-plugin-gcloud-pubsub-custom](https://github.com/mia-0032/fluent-plugin-gcloud-pubsub-custom) gem
for sending the audit events to the following Google Cloud Pub/Sub topics:

- `projects/gitlab-teleport-staging/topics/teleport-staging-events`
- `projects/gitlab-teleport-production/topics/teleport-production-events`

We use a custom-built OCI (Docker) image with the `fluent-plugin-gcloud-pubsub-custom` gem baked into the image.
You can update/modify this image [here](https://gitlab.com/gitlab-com/gl-infra/oci-images/-/tree/main/fluentd/bitnami-ext).

We use [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
for authenticating to Google Cloud. The *Workload Identity* is configured
[here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/modules/teleport-cluster/service-account.tf)
and the required *Roles* are configured
[here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/modules/teleport-project/pubsub.tf).
