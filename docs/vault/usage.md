# How to Use Vault for Secrets Management in Infrastructure

[[_TOC_]]

## Accessing Vault

### Web UI

* Go to <https://vault.gitlab.net/>
* Select `oidc`, leave `Role` empty and click `Sign in with GitLab`
* Don't forget to allow pop-ups for this site in your browser.
* You should now be logged in

Your session token is valid for 24 hours, renewable for up to 7 days and automatically renewed when you use the Web UI before the 24 hours TTL runs out.

Members of the Infrastructure team can also login with admin privileges by entering `admin` in the `Role` input. The admin session token is valid for a maximum of 1 hour (non renewable), as its usage should be limited to troubleshooting.

#### Authentication alternative

If the OIDC authentication fails for any reason, the CLI token (using the method below) can be reused to login in the UI.

* Execute `vault token lookup`

```
Key                            Value
---                            -----
...
id                             <mytoken>
...
ttl                            21h39m34s
```

* Copy the `id` key value, which is the session token
* In the UI, select `Other`, Method `Token`, paste the above token and `Sign In`

### CLI

#### Installing the client

The Hashicorp Vault client is available for most OSes and package managers, see <https://developer.hashicorp.com/vault/downloads> for more information.

The non-official client [`safe`](https://github.com/starkandwayne/safe) is also more user-friendly and convenient for key/value secrets operations, however you will still need the official client above to be able to login. See the [releases](https://github.com/starkandwayne/safe/releases) for prebuilt binaries, and MacOS users will want to read <https://github.com/starkandwayne/safe#attention-homebrew-users> for installing via Homebrew.

#### Access

*Access via Teleport is not implemented yet at the time of this writing (see <https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/15898>) but will eventually be the prefered method for accessing Vault from CLI.*

```shell
eval "$(glsh vault init -)"
glsh vault proxy

# In a new shell
export VAULT_PROXY_ADDR="socks5://localhost:18200"
glsh vault login
```

There are alternative ways for you to connect as well if `glsh` doesn't work for you:

<details>
<summary> SOCKS5 proxy via SSH </summary>

```shell
# In a separate shell session
ssh -D 18200 bastion-01-inf-ops.c.gitlab-ops.internal
# In your first session
export VAULT_ADDR=https://vault.ops.gke.gitlab.net
export VAULT_PROXY_ADDR=socks5://localhost:18200
# If using safe:
alias safe='HTTPS_PROXY="${VAULT_PROXY_ADDR}" safe'
safe target ${VAULT_ADDR} ops
```

</details>

<details>
<summary> port-forwarding via `kubectl` </summary>

```shell
# In a separate shell session
kubectl -n vault port-forward svc/vault-active 8200
# In your first session
export VAULT_ADDR=https://localhost:8200
export VAULT_TLS_SERVER_NAME=vault.ops.gke.gitlab.net
# If using safe:
safe target ${VAULT_ADDR} ops
```

</details>

<details>
<summary> Users of fish shell can use this function </summary>

```shell
# Copy to ~/.config/fish/functions/vault-proxy.fish
function vault-proxy -d 'Set up a proxy to run vault commands'
 set -f BASTION_HOST "lb-bastion.ops.gitlab.com"
 set -Ux VAULT_ADDR "https://vault.ops.gke.gitlab.net"
 set -f VAULT_PROXY_PORT "18200"
 set -Ux VAULT_PROXY_ADDR "socks5://localhost:$VAULT_PROXY_PORT"
 set msg "[vault] Starting SOCKS5 proxy on $BASTION_HOST via $VAULT_PROXY_ADDR"
 if test -n "$TMUX"
  tmux split-pane -d -v -l 3 "echo \"$msg\"; ssh -D \"$VAULT_PROXY_PORT\" \"$BASTION_HOST\" 'echo \"Connected! Press Enter to disconnect.\"; read disconnect'; set -e VAULT_PROXY_ADDR VAULT_ADDR; echo Disconnected ; sleep 3"
 else
  echo >&2 "Open a new shell before using Vault:"
  echo >&2 "$msg"
  ssh -D "$VAULT_PROXY_PORT" "$BASTION_HOST" 'echo "Connected! Press Enter to disconnect."; read disconnect' >&2
  set -e VAULT_PROXY_ADDR VAULT_ADDR
 end
end
```

</details>

Then you can login via the OIDC method:

```shell
vault login -method oidc
```

If you are using `safe`, you will also have to run the following to login with your new token created above:

```shell
vault print token | safe auth token
```

Members of the Infrastructure team can also login with admin privileges (token TTL max of 1 hour, non renewable) with the following:

```shell
vault login -method oidc role=admin
```

After logging in, your Vault token is stored in `~/.vault-token` by default. Alternatively it can be set with the environment variable `VAULT_TOKEN`.

Your token is valid for 24 hours, renewable for up to 7 days using `vault token renew` before the 24 hours TTL runs out.

## Secrets Management

### Secrets Engines

There are currently 3 [KV Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) configured in Vault:

* `ci`: secrets accessed from GitLab CI
* `k8s`: secrets accessed by the [External Secrets operator](https://external-secrets.io/) from the GKE clusters
* `shared`: secrets that can be accessed from both GitLab CI and the External Secrets operator on a case by case basis

The structure of the `ci` and `k8s` secrets is described in their respective sections below.

The `shared` secrets don't have a well-defined structure at the time of this writing.

We are using the `kv` secret store version 2, which has secret versioning enabled. This means that when updating a secret, any previous secret versions can be retrieved by its version number until it is deleted (⚠️  deleting the last version does not delete the previous ones), and they can be undeleted as well. On the other hand, *destroying* a secret will effectively delete it permanently.

See [the Vault documentation about KV version 2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2#usage) to learn how to create/read/update/delete secrets and manage their versions.

There is also another secret engine named `cubbyhole`, this is a temporary secret engine scoped to a token, and destroyed when the token expires. It is especially useful for response wrapping, see the Vault documentation about [Cubbyhole](https://developer.hashicorp.com/vault/docs/secrets/cubbyhole) and [response wrapping](https://developer.hashicorp.com/vault/docs/concepts/response-wrapping) for more information.

### GitLab CI Secrets

#### Structure

CI secrets are available under the following paths:

* `ci/<gitlab-instance>/<project-full-path>/<environment>/...`: to be used for secrets scoped to an environment (when the `environment` attribute is set for a CI job), which are only accessible for this particular environment and none other;
* `ci/<gitlab-instance>/<project-full-path>/<environment>/outputs/...`: to be used for *writing* secrets to Vault scoped to an environment (primarily from Terraform but it can be from other tools), this path is only readable/writable from CI jobs running for protected branches/environments;
* `ci/<gitlab-instance>/<project-full-path>/<environment>/protected/...`: to be used for protected secrets scoped to an environment, this path is only readable from CI jobs running for protected branches/environments;
* `ci/<gitlab-instance>/<project-full-path>/shared/...`: to be used for secrets shared for all environments or when no environments are defined in the pipeline;
* `ci/<gitlab-instance>/<project-full-path>/outputs/...`: to be used for *writing* secrets to Vault (primarily from Terraform but it can be from other tools), this path is only readable/writable by CI jobs running from protected branches;
* `ci/<gitlab-instance>/<project-full-path>/protected/...`: to be used for protected secrets for all environments, this path is only readable from CI jobs running for protected branches/environments.

Additional, a Transit key is created under `transit/ci/<gitlab-instance>-<project-full-path>`, which can be used for encryption, decryption and signing of CI artifacts and anything else. Decryption and signing is restricted to the project, while encryption and signature verification is allowed for all, this can be useful for sharing artifacts securirely between projects. See [the Vault documentation about the Transit secrets engine](https://developer.hashicorp.com/vault/docs/secrets/transit) to learn more about it.

_Terminology:_

* `gitlab instance`: the GitLab instance using Vault secrets in CI
  * `gitlab-com`: our primary `GitLab.com` SaaS environment
  * `ops-gitlab-net`: our ops instance `ops.gitlab.net`
* `project-full-path`: the full path of a project hosted on a GitLab instance, slashes are replaced with underscores in the transit key, role and policy names
* `environment`: the short name of the environment the CI job fetching the secrets is running for: `gprd`, `gstg`, `ops`, ...

Examples:

* `ci/ops-gitlab-net/gitlab-com/gl-infra/my-project/gprd/foo` is a secret named `foo` for the environment `gprd` only from the project `gitlab-com/gl-infra/my-project` on `ops.gitlab.net`
* `ci/gitlab-com/gitlab-com/gl-infra/some-group/my-other-project/shared/bar` is a secret named `bar` for all environments from the project `gitlab-com/gl-infra/some-group/my-other-project` on `gitlab.com`
* `ci/ops-gitlab-net/gitlab-com/gl-infra/my-project/outputs/qux` is a secret named `qux` created by Terraform in a CI job from a protected branch or environment from the project `gitlab-com/gl-infra/my-project` on `ops.gitlab.net`

#### Authorizing a GitLab Project

To enable a GitLab project to access Vault from CI, add the following to its project definition in [`infra-mgmt`](https://gitlab.com/gitlab-com/gl-infra/infra-mgmt):

```terraform
module "project_my-project" {
  ...

  vault = {
    enabled   = true
    auth_path = local.vault_auth_path
  }
}
```

⚠️ Note: if your project doesn't exist yet in `infra-mgmt`, you will need to add and import it (documentation for this to be added later at the time of this writing).

There are additional attributes that you can set to allow access to more secrets paths and policies, see [the project module documentation](https://gitlab.com/gitlab-com/gl-infra/infra-mgmt/-/tree/main/modules/project#input_vault) to learn more about those.

Terraform will then create 2 JWT roles in Vault named `<project-full-path>` for read-only access and `<project-full-path>-rw` for read/write access from protected branches/environments, along with their associated policies:

```
❯ vault read auth/ops-gitlab-net/role/gitlab-com_gl-infra_k8s-workloads_tanka-deployments
Key                        Value
---                        -----
[...]
bound_claims               map[project_id:[401]]
claim_mappings             map[environment:environment]
token_policies             [ops-gitlab-net-project-gitlab-com_gl-infra_k8s-workloads_tanka-deployments]
[...]
❯ vault read auth/ops-gitlab-net/role/gitlab-com_gl-infra_k8s-workloads_tanka-deployments-rw
Key                        Value
---                        -----
[...]
bound_claims               map[project_id:[401] ref_protected:[true]]
claim_mappings             map[environment:environment]
token_policies             [ops-gitlab-net-project-gitlab-com_gl-infra_k8s-workloads_tanka-deployments-rw ops-gitlab-net-project-gitlab-com_gl-infra_k8s-workloads_tanka-deployments]
[...]
```

It will also create the following CI variables in the project:

* `VAULT_AUTH_ROLE:` read-only role name, and read-write role name for each defined protected environment if any
* `VAULT_SECRETS_PATH`: the secrets base path (`ci/<gitlab-instance>/<project-full-path>`)
* `VAULT_TRANSIT_KEY_NAME`: the transit key name relative to `transit/ci`

The following variables are also set at the group level:

* `VAULT_ADDR` / `VAULT_SERVER_URL`: `https://vault.ops.gke.gitlab.net`
* `VAULT_AUTH_PATH`: authentication method path relative to `auth/`, for instance `gitlab-com` or `ops-gitlab-net`
* `VAULT_TRANSIT_PATH`: `transit/ci`

#### Using Vault secrets in CI

Then in a CI job, a secret can be configured like so:

```yaml
my-job:
  secrets:
    TOKEN:
      file: false
      vault: ${VAULT_SECRETS_PATH}/${ENVIRONMENT}/some-service/token@ci
```

This will set the variable `TOKEN` to the value of the key `token` from the secret `some-service` for the current environment.

Note that the name of the KV mount is set at the end of the path with `@ci` here, and `token` is a key from the secret and not part of the actual path of the secret.

A secret can also be stored in a file instead by setting `file: true` like so:

```yaml
my-other-job:
  secrets:
    GOOGLE_APPLICATION_CREDENTIALS:
      file: true
      vault: ${VAULT_SECRETS_PATH}/${ENVIRONMENT}/service-account/key@ci
```

Something like this should appear at the beginning of the CI job output:

```
> Resolving secrets
  Resolving secret "GOOGLE_APPLICATION_CREDENTIALS"...
  Using "vault" secret resolver...
```

See [Use Vault secrets in a CI job](https://docs.gitlab.com/ee/ci/secrets/#use-vault-secrets-in-a-ci-job) and [the `.gitlab-ci.yml` reference](https://docs.gitlab.com/ee/ci/yaml/index.html#secretsvault) for more information.

#### Using Vault secrets in Terraform

This Vault provider configuration allows using Vault in Terraform both from CI and locally from one's workstation [when already logged in](#access):

```terraform
// providers.tf

provider "vault" {
  // address = "${VAULT_ADDR}"

  dynamic "auth_login_jwt" {
    for_each = var.vault_jwt != "" && var.vault_auth_path != "" ? [var.vault_auth_path] : []

    content {
      mount = var.vault_auth_path
      role  = var.vault_auth_role
      jwt   = var.vault_jwt
    }
  }
}

// variables.tf

variable "vault_jwt" {
  type        = string
  description = "Vault CI JWT token"
  default     = ""
  sensitive   = true
}
variable "vault_auth_path" {
  type        = string
  description = "Vault authentication path"
  default     = ""
}
variable "vault_auth_role" {
  type        = string
  description = "Vault authentication role"
  default     = ""
}
variable "vault_secrets_path" {
  type        = string
  description = "Vault secrets path"
  default     = "ops-gitlab-net/gitlab-com/gl-infra/my-project/some-env"
}

// versions.tf

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.9.0"
    }
  }
}
```

And the following has to be added on `.gitlab-ci.yml` to provide the Terraform variables above while also enabling [CI secrets](#using-vault-secrets-in-ci):

```yaml
variables:
  TF_VAR_vault_jwt: ${CI_JOB_JWT}
  TF_VAR_vault_auth_path: ${VAULT_AUTH_PATH}
  TF_VAR_vault_auth_role: ${VAULT_AUTH_ROLE}
  TF_VAR_vault_auth_secrets_path: ${VAULT_SECRETS_PATH}/${CI_ENVIRONMENT_NAME}
```

Then a secret can be fetched using the [`vault_kv_secret_v2` data source](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/kv_secret_v2), and its content can be retrieved from the [`data`](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/kv_secret_v2#data) attribute:

```terraform
data "vault_kv_secret_v2" "some-secret" {
  mount = "ci"
  name  = "${var.vault_secrets_path}/some-secret"
}

resource "google_some_service" "foo" {
  token = data.vault_kv_secret_v2.some-secret.data.token
}
```

Terraform can also write a secret to Vault using the `vault_kv_secret_v2` resource:

```terraform
resource "vault_kv_secret_v2" "database-credentials" {
  mount     = "ci"
  name      = "${var.vault_secrets_path}/outputs/database"
  data_json = jsonencode({
      username = google_sql_user.foo.name
      password = google_sql_user.foo.password
  })
}
```

See the [Vault provider documentation](https://registry.terraform.io/providers/hashicorp/vault/latest/docs) for more information.

### Rotating CI secrets (with Terraform)

By default, the `vault_kv_secret_v2` data source will pull the latest version of a secret, but it can instead pull a specific one by setting the attribute `version`:

```terraform
data "vault_kv_secret_v2" "some-secret" {
  mount   = "ci"
  name    = "${var.vault_secrets_path}/some-secret"
  version = 3
}
```

This allows rotating secrets safely in a controlled manner:

* update the secret in place in Vault, creating a new version:

  ```shell
  vault kv patch ci/ops-gitlab-net/gitlab-com/gl-infra/my-project/pre/some-secret foo=bar
  ```

* this will display the version number for the new secret, but it can also be retrieved it with:

  ```shell
  vault kv metadata get ci/ops-gitlab-net/gitlab-com/gl-infra/my-project/pre/some-secret
  ```

* bump the version in Terraform:

  ```terraform
  data "vault_kv_secret_v2" "some-secret" {
    mount   = "ci"
    name    = "${var.vault_secrets_path}/some-secret"
    version = 4
  }
  ```

* commit, open a merge request, merge and apply
* if for any reason the previous version of the secret needs to be deleted permanently:

  ```
  vault kv delete -versions 3 ci/ops-gitlab-net/gitlab-com/gl-infra/my-project/pre/some-secret
  ```

### External Secrets in Kubernetes

#### Structure

Kubernetes secrets are available under the following paths:

* `k8s/<cluster>/<namespace>/...`: to be used for secrets scoped to a namespace in a particular cluster;
* `k8s/env/<environment>/ns/<namespace>/...`: to be used for secrets shared for the whole the environment, this is useful in the `gstg` and `gprd` where there are multiple clusters using the same secrets.

_Terminology:_

* `cluster`: the name of the GKE cluster the External Secrets are created in
* `environment`: the short name of the environment the Kubernetes clusters fetching the secrets runs in: `gprd`, `gstg`, `ops`, ...
* `namespace`: the namespace the External Secrets are created in

Examples:

* `k8s/ops-gitlab-gke/vault/oidc` is a secret named `oidc` for the namespace `vault` in the cluster `ops-gitlab-gke`
* `k8s/env/gprd/ns/gitlab/redis/foo` is a secret named `redis/foo` for the namespace `gitlab` in the environment `gprd`

#### Using the External Secrets operator within a Kubernetes deployment

The External Secrets operator provides 2 Kubernetes objects:

* a [SecretStore](https://external-secrets.io/v0.5.9/api-secretstore/) specifying the location of the Vault server, the role to authenticate as, the service account to authenticate with, and the targeted secret engine to use. For a given namespace there should be one Secret Store per secret engine.
* an [ExternalSecret](https://external-secrets.io/v0.5.9/api-externalsecret/) creating a Secret object from one or several Vault secrets using a given SecretStore. There can be as many External Secrets as needed, one for each Secret to provision.

The SecretStore uses a dedicated Service Account so that regular workloads are not able to access Vault by themselves, and it is scoped to the namespace it is deployed into.

Before using the operator, a role has to be created in Vault for the namespace the secrets will be provisioned into. This is done in [`environments/vault-production/kubernetes.tf`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/master/environments/vault-production/kubernetes.tf):

```terraform
locals {
  kubernetes_common_roles = {
    [...]

    my-app = {
      service_accounts = ["my-app-secrets"]
      namespaces       = ["my-app"]
    }
  }

  kubernetes_clusters = {
    [...]

    pre-gitlab-gke = {
      environment = "pre"
      roles       = {
        my-app = local.kubernetes_common_roles.my-app
      }
    }

    [...]
  }
}
```

Terraform will then create the role for the given cluster along with its associated policies.

Then a Secret Store can be created with the following:

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-secrets
---
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: my-app
spec:
  provider:
    vault:
      auth:
        kubernetes:
          mountPath: kubernetes/pre-gitlab-gke
          role: my-app
          serviceAccountRef:
            name: my-app-secrets
      path: k8s
      server: https://vault.ops.gke.gitlab.net
      version: v2
```

And finally a basic External Secret can be created with the following:

```yaml
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: some-secret-v1
spec:
  secretStoreRef:
    kind: SecretStore
    name: my-app
  refreshInterval: 0
  target:
    creationPolicy: Owner
    deletionPolicy: Delete
    name: some-secret-v1
    template:
      type: Opaque
  data:
  - remoteRef:
      key: pre-gitlab-gke/my-namespace/some-secret
      property: username
      version: "1"
    secretKey: username
  - remoteRef:
      key: pre-gitlab-gke/my-namespace/some-secret
      property: password
      version: "1"
    secretKey: password
```

See [the External Secrets documentation](https://external-secrets.io/v0.5.9/api-externalsecret/) for more additional information on the ExternalSecret specification, secret data templating and more.

To help with this, some helpers exist in the `gitlab-helmfiles` and `tanka-deployments` repositories.

##### `gitlab-helmfiles` and `gitlab-com`

The chart [`vault-secrets`](https://gitlab.com/gitlab-com/gl-infra/charts/-/tree/main/gitlab/vault-secrets) can be used to create the Secrets Store(s) and External Secrets together:

```yaml
# helmfile.yaml


repositories:
  - name: registry-ops-gl
    url: registry.ops.gitlab.net
    oci: true

releases:
  - name: my-app-secrets
    chart: registry-ops-gl/gitlab-com/gl-infra/charts/vault-secrets
    version: 1.1.0
    namespace: my-app
    installed: {{ .Values | getOrNil "my-app.installed" | default false }}
    values:
      - secrets-values.yaml.gotmpl
```

```yaml
# secrets-values.yaml.gotmpl

---
clusterName: {{ .Environment.Values.cluster }}

externalSecrets:
  some-secret-v1:
    refreshInterval: 0
    secretStoreName: my-app-secrets
    target:
      creationPolicy: Owner
      deletionPolicy: Delete
    data:
      - remoteRef:
          key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
          property: username
          version: "1"
        secretKey: username
      - remoteRef:
          key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
          property: password
          version: "1"
        secretKey: password

secretStores:
  - name: my-app-secrets
    role: my-app
    # path: k8s
  - name: my-app-shared-secrets
    role: my-app
    path: shared

serviceAccount:
  name: my-app-secrets
```

##### `tanka-deployments`

The Secret Store(s) are handled separately for Tanka.

To enable the SecretStore, `externalSecretsRole` has to be set for the environment. Also additional secrets engine can be specified with `secretStorePaths` (defaulting to `k8s`):

```jsonnet
{
  envsData:: {
    pre: {
      namespaceName:: namespaceName,
      externalSecretsRole:: 'my-app',
      // secretStorePaths:: ['k8s', 'shared'],
      ...
    },
  }
}
```

Then the External Secrets can be created with the following:

```jsonnet
local clusters = import 'gitlab/clusters.libsonnet';
local externalSecrets = import 'gitlab/external-secrets.libsonnet';

{
  secrets:: {
    new(env, namespace, appName, labels={}):: {
      local secretKey(name) = externalSecrets.k8sAppSecretKey(clusters[env].clusterName, namespace, appName, name),

      some_secret:
        externalSecrets.externalSecret(
          'some-secret',
          appName,
          namespace,
          labels=labels,
          clusters[env].clusterName,
          data={
            username: {
              key: secretKey('some-secret'),
              property: 'username',
              version: 1,
            },
            password: {
              key: secretKey('some-secret'),
              property: 'password',
              version: 1,
            },
          },
        ),
    },
  },
}
```

See [`lib/gitlab/external-secrets.libsonnet`](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/blob/master/lib/gitlab/external-secrets.libsonnet) for the function definitions.

### Rotating Kubernetes secrets

For a safe and controlled rollout and to ensure that the pods are rotated each time a secret is updated, the secret's name should preferably be prefixed with the version, for example `my-secret-v1`, incrementing the version with each update.

The following instructions are for rotating secrets managed in the `gitlab-helmfiles` repository based on the examples from the [section above](#gitlab-helmfiles-and-gitlab-com), but the same principle can be followed in the other repositories:

* update the secret in place in Vault, creating a new version:

  ```shell
  vault kv patch k8s/my-cluster/my-app/some-secret password=foobar
  ```

* this will display the version number for the new secret, but it can also be retrieved it with:

  ```shell
  vault kv metadata get k8s/my-cluster/my-app/some-secret
  ```

* duplicate the external secret definition, bumping the version number in the name and the specification:

  ```diff
   # secrets-values.yaml.gotmpl

   externalSecrets:
     some-secret-v1:
       refreshInterval: 0
       secretStoreName: my-app-secrets
       target:
         creationPolicy: Owner
         deletionPolicy: Delete
       data:
         - remoteRef:
             key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
             property: username
             version: "1"
           secretKey: username
         - remoteRef:
             key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
             property: password
             version: "1"
           secretKey: password
  +  some-secret-v2:
  +    refreshInterval: 0
  +    secretStoreName: my-app-secrets
  +    target:
  +      creationPolicy: Owner
  +      deletionPolicy: Delete
  +    data:
  +      - remoteRef:
  +          key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
  +          property: username
  +          version: "2"
  +        secretKey: username
  +      - remoteRef:
  +          key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
  +          property: password
  +          version: "2"
  +        secretKey: password
  ```

* commit, open a merge request, merge and deploy
* ensure that the new secret has been created:

  ```shell
  kubectl --context my-cluster --namespace my-namespace get externalsecrets
  kubectl --context my-cluster --namespace my-namespace get secret some-secret-v2
  ```

* ensure that the new secret data matches its value in Vault:

  ```shell
  vault kv get -format json -field data k8s/my-cluster/my-app/some-secret | jq -c
  kubectl --context my-cluster --namespace my-namespace get secret some-secret-v2 -o jsonpath='{.data}' | jq '.[] |= @base64d'
  ```

* update any reference to this secret in the rest of the application deployment configuration to target the new name `some-secret-v2`
* commit, open a merge request, merge and deploy

* ensure that the pods have been rotated and are all using the new secret

  ```shell
  kubectl --context my-cluster --namespace my-namespace get deployments
  kubectl --context my-cluster --namespace my-namespace get pods
  kubectl --context my-cluster --namespace my-namespace describe pod my-app-1ab2c3d4f5-g6h7i
  ```

* remove the old external secret definition:

  ```diff
   # secrets-values.yaml.gotmpl

   externalSecrets:
  -  some-secret-v1:
  -    refreshInterval: 0
  -    secretStoreName: my-app-secrets
  -    target:
  -      creationPolicy: Owner
  -      deletionPolicy: Delete
  -    data:
  -      - remoteRef:
  -          key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
  -          property: username
  -          version: "1"
  -        secretKey: username
  -      - remoteRef:
  -          key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
  -          property: password
  -          version: "1"
  -        secretKey: password
     some-secret-v2:
       refreshInterval: 0
       secretStoreName: my-app-secrets
       target:
         creationPolicy: Owner
         deletionPolicy: Delete
       data:
         - remoteRef:
             key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
             property: username
             version: "2"
           secretKey: username
         - remoteRef:
             key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
             property: password
             version: "2"
           secretKey: password
  ```

* commit, open a merge request, merge and deploy
* ensure that the old secret has been deleted:

  ```shell
  kubectl --context my-cluster --namespace my-namespace get secret some-secret-v1
  ```

### Migrating existing Kubernetes secrets to External Secrets

An existing Kubernetes secret deployed by an older method (helmfile+GKMS, manual, ...) needs to be stored in Vault and be deployed with External Secrets.

⚠️ Consider opening a [Change Request](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/new?issuable_template=change_management) with the instructions below when migrating a secret in production.

The following instructions are for migrating a secrets managed in the `gitlab-helmfiles` repository based on the examples from the [section above](#gitlab-helmfiles-and-gitlab-com), but the same principle can be followed in the other repositories:

* fetch the existing secret value from Kubernetes and store it in to Vault:

  ```shell
  kubectl --context my-cluster --namespace my-namespace get secret some-secret-v1 -o jsonpath='{.data.password}' \
    | base64 -d \
    | vault kv put k8s/my-cluster/my-app/some-secret password=-
  ```

* this will display the version number for the new secret, but it can also be retrieved it with:

  ```shell
  vault kv metadata get k8s/my-cluster/my-app/some-secret
  ```

* duplicate the external secret definition, bumping the version number in the name and the specification:

  ```diff
   # secrets-values.yaml.gotmpl

   externalSecrets:
  +  some-secret-v2:
  +    refreshInterval: 0
  +    secretStoreName: my-app-secrets
  +    target:
  +      creationPolicy: Owner
  +      deletionPolicy: Delete
  +    data:
  +      - remoteRef:
  +          key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
  +          property: password
  +          version: "2"
  +        secretKey: password
  ```

* commit, open a merge request, merge and deploy
* ensure that the new secret has been created:

  ```shell
  kubectl --context my-cluster --namespace my-namespace get externalsecrets
  kubectl --context my-cluster --namespace my-namespace get secret some-secret-v2
  ```

* ensure that the new secret data matches its value in Vault:

  ```shell
  vault kv get -format json -field data k8s/my-cluster/my-app/some-secret
  kubectl --context my-cluster --namespace my-namespace get secret some-secret-v2 -o jsonpath='{.data}' | jq '.[] |= @base64d'
  ```

* ensure that the new secret data matches the old one:

  ```shell
  kubectl --context my-cluster --namespace my-namespace get secret some-secret-v1 -o jsonpath='{.data}' | jq '.[] |= @base64d' | sha256sum
  kubectl --context my-cluster --namespace my-namespace get secret some-secret-v2 -o jsonpath='{.data}' | jq '.[] |= @base64d' | sha256sum
  ```

* if this is a production secret, post the checksum results above as proof in the associated issue or merge request

* update any reference to this secret in the rest of the application deployment configuration to target the new name `some-secret-v2`
* commit, open a merge request, merge and deploy

* ensure that the pods have been rotated and are all using the new secret

  ```shell
  kubectl --context my-cluster --namespace my-namespace get deployments
  kubectl --context my-cluster --namespace my-namespace get pods
  kubectl --context my-cluster --namespace my-namespace describe pod my-app-1ab2c3d4f5-g6h7i
  ```

* remove the old external secret definition:

  ```diff
   # secrets-values.yaml.gotmpl

   externalSecrets:
  -  some-secret-v1:
  -    refreshInterval: 0
  -    secretStoreName: my-app-secrets
  -    target:
  -      creationPolicy: Owner
  -      deletionPolicy: Delete
  -    data:
  -      - remoteRef:
  -          key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
  -          property: password
  -          version: "1"
  -        secretKey: password
     some-secret-v2:
       refreshInterval: 0
       secretStoreName: my-app-secrets
       target:
         creationPolicy: Owner
         deletionPolicy: Delete
       data:
         - remoteRef:
             key: "{{ .Environment.Values.cluster }}/my-app/some-secret"
             property: password
             version: "2"
           secretKey: password
  ```

* commit, open a merge request, merge and deploy
* ensure that the old secret has been deleted:

  ```shell
  kubectl --context my-cluster --namespace my-namespace get secret some-secret-v1
  ```
