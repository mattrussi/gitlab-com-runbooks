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
    VSCode-->>GitLab: /api/v4/code_suggestions/completions
    GitLab-->>Ingress: /v2/completions
    Ingress-->>ModelGateway: /v2/completions
    ModelGateway-->>VertexAI: code to complete
    VertextAI-->>ModelGateway: code
    ModelGateway-->>Ingress: 200 OK with code completion
    Ingress-->>GitLab: 200 OK with code completion
    GitLab-->>VSCode: 200 OK with code completion
```

* VSCode: This is the client where the user is writing and getting autocompletion.
* Ingress: NGINX Controller for Kubernetes to expose service to the internet.
* ModelGateway: Entry point for code suggestions and will route requests accordingly.
* VertexAI: Third-party API that provides inferences from ML models.

Mode detailed architecture description avialable in:
<https://docs.gitlab.com/ee/development/ai_architecture.html> and in
the [Architecture
overview](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/architecture.md)
in the source repository.

<!-- ## Performance -->

## Scalability

### Horizontal

We have the ability to scale the Model Gateway horizontally by increasing the [replica](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/infrastructure/ai-assist/values.yaml) count:

1. [Model Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/d09f5635ee91e24d0e6059ef9d296ba89f94bd6b/infrastructure/ai-assist/values.yaml#L21)

To apply these changes, refer to [deployment guide](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#deploying-to-the-kubernetes-cluster).

### Vertical

## Availability

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

## Links to further Documentation

* [Deploying to the kubernetes cluster](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#deploying-to-the-kubernetes-cluster)
