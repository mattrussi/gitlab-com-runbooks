<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Code_suggestions Service

* [Service Overview](https://dashboards.gitlab.net/d/code_suggestions-main/code-suggestions-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22code_suggestions%22%2C%20tier%3D%22inf%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::CodeSuggestions"

## Logging

* [mlops](https://log.gprd.gitlab.net/goto/d21f8880-f0a7-11ed-a017-0d32180b1390)
* [request rate](https://log.gprd.gitlab.net/goto/c4faac00-f612-11ed-a017-0d32180b1390)
* [request latency](https://log.gprd.gitlab.net/goto/b423c240-f612-11ed-8afc-c9851e4645c0)

<!-- END_MARKER -->

## Summary

Service responsible for providing [code completion for the user in their editor](https://youtu.be/WnxBYxN2-p4) using AI.

## Architecture

```mermaid
sequenceDiagram
    VSCode-->>Ingress: /v2/completions
    Ingress-->>ModelGateway: /v2/completions
    ModelGateway-->>TritonServer: code to complete
    TritonServer-->>ModelGateway: code
    ModelGateway-->>Ingress: 200 OK with code completion
    Ingress-->>VSCode: 200 OK with code completion
```

* VSCode: This the the client where the user is writing the and getting autocompletion.
* Ingress: NGINX Controller for Kubernetes to expose service to the internet.
* ModelGateway: Entry point for code suggestions and will route requests accordingly.
* TritonServer: [Inference Server](https://github.com/triton-inference-server/server) that loads our model data from the NFS server into memory.

Mode detailed architecture description avialable in:
<https://docs.gitlab.com/ee/development/ai_architecture.html> and in
the [Architecture
overview](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/architecture.md)
in the source repository.

<!-- ## Performance -->

## Scalability

### Horizontal

We have the ability to scale horizontally both the Model Gateway and the Triton Server by increasing the [replica](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/infrastructure/ai-assist/values.yaml) count:

1. [Model Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/d09f5635ee91e24d0e6059ef9d296ba89f94bd6b/infrastructure/ai-assist/values.yaml#L21)
1. [Triton Server](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/d09f5635ee91e24d0e6059ef9d296ba89f94bd6b/infrastructure/ai-assist/values.yaml#L34)

To apply these changes, refer to [deployment guide](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#deploying-to-the-kubernetes-cluster).

### Vertical

## Availability

* [Triton Server dashboard](https://dashboards.gitlab.net/d/code_suggestions-triton/code-suggestions-triton-server?orgId=1)

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

## Links to further Documentation

* [Deploying to the kubernetes cluster](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#deploying-to-the-kubernetes-cluster)
