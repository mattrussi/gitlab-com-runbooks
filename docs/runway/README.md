# Runway

Runway is GitLab's internal Platform as a Service, which aims to enable teams to deploy and run their services quickly
and safely.

## Architecture

For an overview of Runway's architecture, see
<https://gitlab.com/gitlab-com/gl-infra/platform/runway/docs/-/blob/master/architecture.md>

## Observability

Runway includes a default set of metrics, dashboards and logging for every service, with the ability for service
maintainer to expand them. For details, see [the Runway Observability runbook](./observability.md).

## Troubleshooting

The Runway platform is comprised of several interdependent components. In case of issues with a Runway service, there
are several potential failure points you can investigate:

### Runway deployment tasks

Every Runway service must include in its `.gitlab-ci.yml` configuration the Runway CI Tasks
in charge of preparing and triggering pipelines in the deployment project (see [this onboarding
step](https://gitlab.com/gitlab-com/gl-infra/platform/runway/docs/-/blob/master/onboarding-new-service.md?ref_type=heads#4-update-your-projects-gitlab-ciyml-file)). In case of failed or missing jobs at this stage, a likely
cause is a misconfigured `include` block on the  `.gitlab-ci.yml` configuration.

### Runway deployment project

The service project's pipeline triggers a child pipeline on a Runway-generated deployment
project, where the Terraform changes are actually executed. Thus, deployment errors, when they occur, are likely to
happen at this stage. Some known issues you may encounter:

- Error downloading parent pipeline artifacts

If you see the following in your failed pipeline:

```sh
$ curl -f -s -S --location --output artifacts.zip --header "JOB-TOKEN:$CI_JOB_TOKEN" "${CI_API_V4_URL}/projects/${SOURCE_PROJECT_ID}/jobs/${PARENT_ARTIFACTS_JOB_ID}/artifacts"
curl: (22) The requested URL returned error: 404
```

(example failed pipeline [here](https://gitlab.com/gitlab-com/gl-infra/platform/runway/deployments/code-viewer-test-fknidg/-/jobs/4925342009))

It means there was a permission issue between the service and the deployment project. Make sure [this step of the
onboarding process](https://gitlab.com/gitlab-com/gl-infra/platform/runway/docs/-/blob/master/onboarding-new-service.md#3-allow-ci-job-tokens-from-the-deployment-project-to-access-your-project)
was followed. Additionally, since the cross-project artifacts downloads feature requires a GitLab subscription, this
problem is known to occur if the service project is hosted on a namespace with a Free plan.

- Service container does not start properly

If you see the following in your failed pipeline:

```
Revision 'XXXX-XXXX' is not ready and cannot serve traffic.
```

(example failed pipeline [here](https://gitlab.com/gitlab-com/gl-infra/platform/runway/deployments/code-viewer-test-fknidg/-/jobs/5000677403))

It means there was a problem booting up the container image built for the service. This could indicate an issue with
Runway's Terraform configuration, but in most cases it indicates an issue with the service deployment image, which could
be due to an application error or a misconfigured `Dockerfile`, among other reasons. The error output will include a
link to the GCP Log Viewer where you can gather additional details.

### Runway provisioner

The [Runway Provisioner](https://gitlab.com/gitlab-com/gl-infra/platform/runway/provisioner/) is in charge of creating
and maintaining the components required for service deployments. A missing or misbehaving deployment project may
indicate problems with the provisioner. Make sure that [this onboarding
step](https://gitlab.com/gitlab-com/gl-infra/platform/runway/docs/-/blob/master/onboarding-new-service.md#1-add-a-service-in-the-inventoryjson-in-the-provisioner-project-create-an-mr)
was followed correctly, and check for failed pipelines in the Provisioner project.

### GCP

Ultimately, Runway deployments are provisioned via GCP resources. Specifically, we are using [Cloud
Run](https://cloud.google.com/run/) for the service runtime, which is an offering we don't have too much previous
experience with. Make sure to check the [Getting help with GCP support and Rackspace Runbook](../uncategorized/externalvendors/GCP-rackspace-support.md)
in case you have any questions or suspect an issue related to the cloud resources.

## Rollbacks

The runway platform has redimentary support for rollbacks in case of a bad deployment, however "roll forward" (`git revert` bad code and deploy) is the preferred approach. Rollbacks are done by going to your service project, going to the pipeline history and finding the pipeline on the commit you wish to revert to, and re-running the "🚀 Production Deploy 100%" job from that pipeline.
