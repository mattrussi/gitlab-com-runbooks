# Pipeline Validation Service

This is an external service, configured into GitLab, that checks CI Pipelines before they are even started (via a web hook).

See https://docs.gitlab.com/ee/administration/external_pipeline_validation.html for the general case

Readiness review is at https://gitlab.com/gitlab-com/gl-infra/readiness/-/issues/17

The actual external service for gitlab.com is provided and run by Trust & Safety (see https://gitlab.com/gitlab-com/gl-security/security-operations/trust-and-safety/pipeline-validation-service); this runbooks is largely targeted at operational matters for SREs responsible for .com.  For many *immediate* purposes we can treat it as a blackbox external service, although we do have some visibility/controls if we have to in an emergency.

## Status codes

The service responds to requests from .com at the `/validate` endpoint. As per the [spec](https://docs.gitlab.com/ee/administration/external_pipeline_validation.html#usage), it replies with the following status codes:

- `200`: will cause .com to accept pipeline
- `406`: will cause .com to reject pipeline
- `500`: will cause .com to accept pipeline and log event

The service supports a read-only mode (enabled by setting the `PIPELINE_VALIDATION_MODE` environment variable to `read-only`). In this mode, the service will perform its usual logic and logging, but always return status code `200`, effectively becoming merely an observer.

## Failure modes

TODO: how it can fail (too restrictive, too permissive), and reasonable courses of actions (disable mostly, I guess, but tease these out)

## Alerts
 
TODO: once we have the requisite metrics (from the readiness review), and alerting, we need to note the key alerts and key actions to take in various scenarios; closely related to Failure modes (actions are likely to be similar), but we're focusing on somewhat more prescriptive responses like 'Got Alert X, investigate Y, perform action Z if conditions A and B hold' .  Or, more wordy descriptions of criteria involved in making appropriate decisions.  We need at least one for each specific alert that can fire.

## Logging

The raw logs can always be seen in the GCP console, either via the CloudRun [log viewer](https://console.cloud.google.com/run/detail/us-central1/pipeline-validation-service/logs?project=glsec-trust-safety-live) or in [StackDriver](https://console.cloud.google.com/logs/viewer?advancedFilter=resource.type%20%3D%20%22cloud_run_revision%22%0Aresource.labels.service_name%20%3D%20%22pipeline-validation-service%22%0Aresource.labels.location%20%3D%20%22us-central1%22%0A%20severity%3E%3DDEFAULT&project=glsec-trust-safety-live)

The logs will also be ingested into Elasticsearch (Details TBD)

TODO: what details are included in the logs (non-direct identifiers so it's not strictly PII) and scripts/processes we can use to map those back to users/groups/projects if we had to. 

## Metrics 

TODO: Explain the *key* metrics available (with links to https://thanos.gitlab.net/graph.); we can assume general familiarity with the golang built in ones, and *roughly* what the http metrics are, but need to point out which labels are meaningful
TODO: Links to dashboards (we'll have to create those first, and we might need some actual real-life data from at least staging to makethose look useful)

## Rules fetching

The rules used by the service are periodically queried from a Git repository (TODO: add URL here) through HTTP requests. Anytime that the HEAD of the configured Git branch is determined to have changed, a Git pull is executed and rules updated.

## Control

TODO: The feature flag and how to disable the use of the service in a hurry
TODO: Who is responsible for read-only vs active mode in the service (T&S) and how to get that changed if necessary
TODO: The env vars for the URL, Token, and Timeout, Git rules repository name, branch, private and deploy tokens; @cmiskell to add this when details are finalized. 
