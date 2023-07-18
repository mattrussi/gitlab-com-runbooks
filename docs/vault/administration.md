# Vault Administration

## Adding a GitLab instance to Vault

In order to enable authentication to Vault from CI for a GitLab instance, add it to the `jwt_auth_backends` map in [`environments/vault-production/vault_config.tf`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/environments/vault-production/vault_config.tf):

```terraform
module "vault-config" {
  [...]

  jwt_auth_backends = {
    [...]

    ops-gitlab-net = {
      description  = "GitLab CI JWT for ops.gitlab.net"
      jwks_url     = "https://ops.gitlab.net/-/jwks"
      bound_issuer = "https://ops.gitlab.net"
    }
  }

  [...]
}
```

Terraform will then configure Vault with the JWT authentication method and some default policies for this GitLab instance.

## Adding a Kubernetes cluster for authentication and the External Secrets Operator

### Master access IP allowlisting

The `ops-gitlab-gke` cluster (which is hosting the Vault service) has to be allowed to connect to the target cluster to be able to do the Service Account verification. This can be done by adding the named IP addresses `gitlab-gke-01` and `gitlab-gke-02` from the `gitlab-ops` project to the `authorized_master_access` parameter of the GKE cluster module, see [this merge request](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/merge_requests/4057) for an example.

### Kubernetes Authentication secrets

To be able to authenticate into a Kubernetes Cluster with Vault, a service account with the necessary permissions needs to be installed to enable Vault to dynamically create temporary service accounts and roles in the cluster. This can be done by installing the Helm chart [`vault-k8s-secrets`](https://gitlab.com/gitlab-com/gl-infra/charts/-/tree/main/gitlab/vault-k8s-secrets):

```yaml
environments:
  pre:
    values:
      - [...]
        vault-k8s-secrets:
          installed: true
```

This will also create a secret `vault-k8s-secrets-token` which will be used when configuring Vault below.

See the [Vault documentation about the Kubernetes secrets engine](https://developer.hashicorp.com/vault/docs/secrets/kubernetes) for more information.

### External Secrets operator

The [External Secrets operator](https://external-secrets.io/) can be installed in a Kubernetes cluster by enabling it in [`bases/environments.yaml`](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/bases/environments.yaml) in the [`gitlab-helmfiles`](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles) repository:

```yaml
environments:
  pre:
    values:
      - [...]
        external_secrets:
          installed: true
          # renovate: datasource=helm depName=external-secrets registryUrl=https://charts.external-secrets.io versioning=helm depType=pre
          chart_version: 0.7.0
```

See the [Vault documentation about the Kubernetes authentication method](https://developer.hashicorp.com/vault/docs/auth/kubernetes) for more information.

### Vault configuration

The cluster information must be saved in a Vault secret that will be used by Terraform to configure the Kubernetes authentication method and/or the Kubernetes secrets engine for this cluster:

```shell
KUBERNETES_HOST="$(kubectl config view -o jsonpath='{.clusters[?(@.name == "gke_gitlab-pre_us-east1_pre-gitlab-gke")].cluster.server}')"
CA_CERT="$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name == "gke_gitlab-pre_us-east1_pre-gitlab-gke")].cluster.certificate-authority-data}' | base64 -d)"

# if the chart vault-k8s-secrets has NOT been installed
vault kv put ci/ops-gitlab-net/gitlab-com/gl-infra/config-mgmt/vault-production/kubernetes/pre-gitlab-gke host="${KUBERNETES_HOST}" ca_cert="${CA_CERT}"

# if the chart vault-k8s-secrets has been installed
JWT_TOKEN="$(kubectl --namespace vault-k8s-secrets get secret vault-k8s-secrets-token -o jsonpath='{.data.token}' | base64 -d)"
vault kv put ci/ops-gitlab-net/gitlab-com/gl-infra/config-mgmt/vault-production/kubernetes/pre-gitlab-gke host="${KUBERNETES_HOST}" ca_cert="${CA_CERT}" service_account_jwt="${JWT_TOKEN}"
```

Finally, add the cluster in [`environments/vault-production/kubernetes.tf`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/environments/vault-production/kubernetes.tf):

```terraform
locals {
  [...]

  kubernetes_clusters = {
    [...]

    pre-gitlab-gke = {
      environment   = "pre"
      auth_roles    = {}
      secrets_roles = {}
    }

    [...]
  }
}
```

Terraform will then configure Vault with the Kubernetes/JWT authentication method and some default policies for this cluster.
