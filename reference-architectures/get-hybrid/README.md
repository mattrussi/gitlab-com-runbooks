# GitLab GET Hybrid Environment SLO Monitoring

This reference architecture is designed for use within a [GET](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit)
Hybrid environment, with Rails and Sidekiq services running inside Kubernetes, and Gitaly running on VMs.

## Further Reading

1. [GET Hybrid Environment](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit/-/blob/main/docs/environment_advanced_hybrid.md) documentation.

## Monitored Components

### `webservice` Service

#### Service Level Monitoring

| **Component** | **Apdex** | **Error Ratio** | **Operation Rate** |
| ------------- | --------- | --------------- | ------------------ |
| `puma`        | ✅         | ✅               | ✅                  |

#### Saturation Monitoring

None yet. Arriving in <https://gitlab.com/gitlab-com/runbooks/-/issues/79>.
