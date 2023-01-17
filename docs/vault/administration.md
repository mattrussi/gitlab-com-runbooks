# Vault Administration

## Adding a GitLab instance to Vault

⚠️ `vault.ops.gke.gitlab.net` is an internal endpoint, making it only accessible from the `ops` runners at this stage, which are not currently configured on `gitlab.com`. Because of this, retrieving CI secrets from Vault is only possible from `ops.gitlab.net` at the moment. See [this issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/16235) for the investigation on how to enable access to Vault from CI on `gitlab.com`.

In order to enable authentication to Vault from CI for a GitLab instance, add it to the `jwt_auth_backends` map in [`environments/vault-production/vault_config.tf`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/environments/vault-production/vault_config.tf):

```terraform
module "vault-config" {
  [...]

  jwt_auth_backends = {
    [...]

    ops-gitlab-net = {
      description  = "GitLab CI JWT for ops.gitlab.net"
      jwks_url     = "https://ops.gitlab.net/-/jwks"
      bound_issuer = "ops.gitlab.net"
    }
  }

  [...]
}
```

Terraform will then configure Vault with the JWT authentication method and some default policies for this GitLab instance.

## Setting Up the External Secrets Operator for a namespace in a Kubernetes Cluster

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

⚠️ The `ops-gitlab-gke` cluster (which is hosting the Vault service) has to be allowed to connect to the target cluster to be able to do the Service Account verification. This can be done by adding the named IP addresses `gitlab-gke-01` and `gitlab-gke-02` from the `gitlab-ops` project to the `authorized_master_access` parameter of the GKE cluster module, see [this merge request](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/merge_requests/4057) for an example.

Then the cluster information must be saved in a Vault secret that will be used by Terraform to configure the Kubernetes authentication for this cluster:

```sh
KUBERNETES_HOST="$(kubectl config view -o jsonpath='{.clusters[?(@.name == "gke_gitlab-pre_us-east1_pre-gitlab-gke")].cluster.server}')"
CA_CERT="$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name == "gke_gitlab-pre_us-east1_pre-gitlab-gke")].cluster.certificate-authority-data}' | base64 -d)"

vault kv put ci/ops-gitlab-net/config-mgmt/vault-production/kubernetes/pre-gitlab-gke host="${KUBERNETES_HOST}" ca_cert="${CA_CERT}"
```

Finally, the cluster has to be added in [`environments/vault-production/kubernetes.tf`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/environments/vault-production/kubernetes.tf):

```terraform
locals {
  [...]

  kubernetes_clusters = {
    [...]

    pre-gitlab-gke = {
      environment = "pre"
      roles       = {}
    }

    [...]
  }
}
```

Terraform will then configure Vault with the Kubernetes/JWT authentication method and some default policies for this cluster.

See the [Vault documentation about Kubernetes authentication](https://developer.hashicorp.com/vault/docs/auth/kubernetes) for more information.
