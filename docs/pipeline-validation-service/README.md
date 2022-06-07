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

1. Service outage - in the case of a complete service outage, pipelines will default to authorized, which would result in abusive pipelines being executed, however it won't affect the running of any pipelines as it the service request will timeout after 1 second as per the `DEFAULT_VALIDATION_REQUEST_TIMEOUT` configuration.
2. Overly permissive rule - in the case where an overly permissive rule is deployed abusive jobs would no longer be blocked in the same way. The rollout of changes will need to be monitored closely by the engineering teams in order to ensure rule changes are having the expected results.
3. Overly restrictive rule - in the case where an overly restrictive rule is deployed legitimate jobs would start to be blocked. This would be observed by an increase in the rate of pipeline validation failures. If this type of failure is observed, the first course of action would be to rollback the most recent rule change.

### Rollout / Rollback

#### Rollout

Rollout is done by triggering manual CI jobs associated with the desired rollout percentage

![Screen_Shot_2021-05-05_at_3.55.10_PM](https://gitlab.com/gitlab-com/gl-security/security-operations/trust-and-safety/pipeline-validation-service/uploads/2b712e971e2a27082446fe380082729b/Screen_Shot_2021-05-05_at_3.55.10_PM.png)

#### Rollback

Rollbacks are executed by running a manual pipeline with the `ROLLBACK_REVISION` pipeline variable set to the desired rollback revision.

A manual pipeline can be run from: [https://gitlab.com/gitlab-com/gl-security/security-operations/trust-and-safety/pipeline-validation-service/-/pipelines/new]().

## Alerts

Currently there are no alerts in place for this service. Once we are able to establish metrics for baseline activity we intend to setup alerts around the rate at which pipelines are being blocked and alert when that metric goes out of range. We may also uncover better metrics for alerting as we use the service more.

## Logging

Logs are ingested into Elasticsearch and can be searched via the [pubsub-pvs-inf-gprd\*](https://log.gprd.gitlab.net/app/management/kibana/indexPatterns/patterns/4858f3a0-a312-11eb-966b-2361593353f9#/?_a=h@9293420) index.

The logs can be observed from both sides:
* PVS (logs from the service itself): https://log.gprd.gitlab.net/goto/0fa08b4c0506cdee202d4b58736c7330
* GitLab (logging the rejection): https://log.gprd.gitlab.net/goto/764d373889cb1d9f6fd6f7f93856198c
   * There is some duplication/repeat logging here, so raw counts may be misleading

The PVS logs are likely more immediately useful as they show *why* the job was rejected, but it may be helpful to correlate with what GitLab saw.

Useful attributes emitted to the PVS logs:

* `correlation_id`
* `mode` active or passive
* `failure_reason` reason for the failure if applicable
* `msg` additional details about the failure if applicable
* `rejection_hint` an indicator of the specific rule failure if applicable
* `status_code` status code returned to as part of the request (200, 406, or 500)
* `user_id` id of the user who created the pipeline
* `validation_status` pass or fail
* `validation_input` the full CI script input that triggered a validation failure

An example of logging that happens per request on the `/validate` endpoint:

```json
# Service request acknowledgement
{"correlation_id":"123","level":"info","mode":"active","msg":"received request","time":"2021-04-22T09:28:15+02:00"}
# Service request outcome
{"correlation_id":"123","failure_reason":"invalid_script","level":"warning","mode":"active","msg":"pipeline rejected due to invalid script string","pipeline_sha":"9459c735bdc2352b8169789e5cc61b2a382d6f25","project_id":35,"rejection_hint":"xmr","status_code":406,"time":"2021-04-22T09:28:15+02:00","user_id":37,"validation_status":"fail"}
# HTTP server generic response log entry
{"content_type":"text/plain; charset=utf-8","correlation_id":"123","duration_ms":0,"host":"127.0.0.1:8080","level":"info","method":"POST","msg":"access","proto":"HTTP/1.1","referrer":"","remote_addr":"127.0.0.1:65204","remote_ip":"127.0.0.1","status":406,"system":"http","time":"2021-04-22T09:28:15+02:00","ttfb_ms":0,"uri":"/validate?token=[FILTERED]","user_agent":"HTTPie/2.4.0","written_bytes":15}
```

## Metrics

A basic metrics dashboard exists at https://dashboards.gitlab.net/d/pvs-main/pvs-overview

The primary observability metrics available today are Apdex, Error Rate, and RPS. These metrics can be used to observe any instability or unexpected change in the service utilization.

## Rules

For the initial version of the service a static set of rules are defined in the [rules.yml](https://gitlab.com/gitlab-com/gl-security/security-operations/trust-and-safety/pipeline-validation-service/-/blob/master/rules/rules.yaml). These rules can be on a granular level to active or passive mode.

**NOTE: NOT CURRENTLY IMPLEMENTED** The next iteration (implemented in https://gitlab.com/gitlab-com/gl-security/security-operations/trust-and-safety/pipeline-validation-service/-/merge_requests/31) will support granular control over the state of each rule. The rules are stored in a separate repository, which will be checked on a regular basis for new rules. When new or changed rules are found, they are loaded into the service and the configuration is updated.

## Control

### Emergency Disabling

In the event that this service is causing too many false positives (or some other large problem) and it needs to be disabled quickly, there are two methods:
1. Feature Flag: Disable the `ci_external_validation_service` flag; using chatops in #production in Slack:
  * `/chatops run feature set ci_external_validation_service false`.
  * However, the feature flag may be removed in future, so if this returns an error about the flag not existing, use the next method instead
1. Remove the configured URL: Using an admin-level Private Access Token in $TOKEN:
  * ```curl --request PUT --header "PRIVATE-TOKEN: $TOKEN" "http://gitlab.com/api/v4/application/settings?external_pipeline_validation_service_url="```
  * A UI may be provided in future.

### Readonly vs Active

Active/read-only mode of the pipeline validation service gets set during the deployment. The mode is stored in an environment variable that gets forwarded to Cloud Run in `--set-env-var` parameter to `gcloud run deploy`. The variable name is `PIPELINE_VALIDATION_MODE` and it gets injected into a deployment build when it starts. It is defined in the secret variables page that can be accessed from the Pipeline Validation Service project -> Settings -> CI/CD -> Variables (expand).

In order to enable the `read-only` mode the contents of this secret variable needs to be exactly `read-only`. For active mode it can be set to `active` but a value that is not `read-only` will be considered to be `active` automatically.

After a change to `PIPELINE_VALIDATION_MODE` is made, a new deployment needs to be done to change the mode.

### GitLab Configuration

This feature is configured in GitLab using either environment variables or application settings, with the latter taking precedence.  In practice, we use application settings because they live in the database and are modifiable live with API calls (and perhaps a Web UI in future), without having to do full deployments/restarts across the fleet.

The settings are:
* external_pipeline_validation_service_url
* external_pipeline_validation_service_token
* external_pipeline_validation_service_timeout

The presence of a configured URL is (in addition to the feature flag which may be removed) sufficient for GitLab to start making the checks; therefore when (re-)enabling, ensure you have set the token (and probably timeout) first before setting the URL.

To set these options, obtain an admin-level Personal Access Token and run something like ```curl --request PUT --header "PRIVATE-TOKEN: $TOKEN" "http://gitlab.com/api/v4/application/settings?external_pipeline_validation_service_url=$VALUE"``` (the setting name varies in the obvious manner).

The token is optional; if provided it is passed to the external service in a header (`X-Gitlab-Token`), the alternative being a query parameter embedded in the URL.  We use the token/header functionality for the GitLab implementation of PVS so that it is unlikely to logged in any normal scenarios.

The values for the URL and Token are saved in 1Password, in the Engineering Vault in an item called `Pipeline Authorization Configuration`
