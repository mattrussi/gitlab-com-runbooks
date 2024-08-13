# Duo Chat Runbook

## Table of Contents

- [Overview](#overview)
- [Quick Links](#quick-links)
- [Duo Chat Error Codes](#types-of-duo-chat-errors)
- [Further troubleshooting](#further-troubleshooting)
- [Tracing Llm Logs](#tracing-request-logs-from-gitlab-rails-to-the-ai-gateway)

## Overview

When you encounter a Duo Chat error code, it is not always clear where the error comes from and which team is responsible. The following runbook should be give any GitLab team member a quick start guide for debugging Duo Chat errors.

## Quick Links

- [Anthropic API Status Page](https://status.anthropic.com/)
- [AI Gateway Grafana Dashboard](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1)

### Logs

Log links for various environments can be found [here](../logging#quick-start).

Different deployments use different indexes. AN The following indexes are most helpful when debugging Duo Chat:

- AI Gateway logs are in the `pubsub-mlops-inf-gprd-*` index
- GitLab Rails Sidekiq logs are in the `pubsub-sidekiq-inf-gprd*` index
  - When searching this index, filtering on `json.subcomponent : "llm"` ensures you are only include
- GitLab Rails logs are in the the `pubsub-rails-inf-gprd-*` index

### Extra Kibana links

You can find other helpful log searches by looking at saved Kibana objects with the [`group::ai_framework` tag](https://log.gprd.gitlab.net/app/management/kibana/objects).

- [AI Gateway error rates and response statuses](https://log.gprd.gitlab.net/app/dashboards#/view/5f334d60-cfd7-11ee-bc6b-0b206b291ea1?_g=h@2294574)
- [AI Gateway Error Rate](https://log.gprd.gitlab.net/app/dashboards#/view/52e09bf4-a739-4686-9bb3-2f6bf1d69cab?_g=h@2294574)

## Types of Duo Chat Errors

All of GitLab Duo Chat [error codes are documented in the following](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/user/gitlab_duo_chat/troubleshooting.md#the-gitlab-duo-chat-button-is-not-displayed) page. To discover what the issue is please use the error code prefix letter to help choose where to search in Elastic logs.

### Error Code Layer Identifier

| Code | Layer           |
|------|-----------------|
| M    | Monolith - A network communication error in the monolith layer.     |
| G    | AI Gateway - A data formatting/processing error in the AI gateway layer.     |
| A    | Third-party API - An authentication or data access permissions error in a third-party API.|

### Debugging Error Codes A1000-6000

Normally, when you recieve an error code starting with 'A', there's an issue regarding either a timeout or limit access due to rate limiting, etc with our third party llm provider. The first step to take is make sure their are no on-going outages.

Here are the following steps to go through:

Check to see the Anthropic Status page is not reporting any issues:

- [Anthropic API Status Page](https://status.anthropic.com/)

Check to see if Google Cloud Platform is currently not reporting any issues:

- [Google Cloud Platform Issues](https://status.cloud.google.com/)

If there's a degredation of service from one of our LLM providers, you still won't know what blast radius the degredation of services is causing to Duo Chat. We have a grafana dashboard that provides a better overivew of the following issues we may be seeing [Grafana AIGW Dashboard](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1)

The most valuable dashboards to provide an overall health status are `Aggregated Service Level Indicators (𝙎𝙇𝙄𝙨)`

### Debugging Error Codes M3002 - M3004

The issue most likely exists within the Monolith. Look for this error in the Sidekiq logs.

1. Filter out json logs to the subcomponent `llm.log` with `json_subcomponent.keyword : "llm"`
2. Filter out error codes with the specific M error code with `json.error_code : "<error_code>" `
3. Check to see issue occurs with a specific user with `json.meta.user : "<user_name>" `
4. Make sure the "Calendar Icon" has the query active for the relevant issue. The default time stamp is 15 minutes realtive from the current date.

The following should provide enough information to boil down error logs for a specific user, error code, and all relevant llm logs that follow underneath our [AI logs](https://docs.gitlab.com/ee/administration/logs/#llmlog). Some common issues that cause the following error are:

1. Rails application having issue with an access check for the current resource.
2. Duo features aren't enabled with the group or project.

### Debugging Error Codes M3005

The following error is pretty straightforward for reasoning. The M3005 error code indicates that the user is requesting a chat capability that belongs to a higher add-on tier, which the user does not currently have access to. This error occurs when attempting to use features or functionalities that are not included in the user's current subscription level or plan.

**Please report this issue to the development team #g_ai_framework#.** It most likely indicates an issue with the access control for guarding unit primitives.

### Debugging Error Codes M4000

The following all relate towards a slash command issues.

| Slash Command | Tool | SME Slack Channel |
|---------------|------|------------|
| /troubleshoot              |      | `#f_ci_rca`        |
| /explain            |      | `#g_code_creation`           |
| /tests             |      | `#g_code_creation`           |
| /refactor | |`#g_code_creation` |
| /summarize_comments             |      |  `#f_plan_ai`          |
| /refactor            |      |  `#g_code_creation`          |
| /vulnerability_explain            |      | `#f_ci_rca`           |

### Tracing request logs from GitLab Rails to the AI Gateway

We utilize a `correlation_id` attribute to track and correlate log entries across both our Rails application and AIGW environments. This unique identifier serves as a key to tie together logs for different systems and components.

With a `correlation_id` from GitLab Rails or Sidekiq logs, you can find the same request in the AI Gateway:

- Access the `pubsub-mlops-inf-gprd-*` index:
- Filter for the logs with `json.jsonPayload.correlation_id : <correlation_id`
- _optional_: Click on the expanded logs icon and select "Surrounding documents" to view logs within relative same time stamp.

## Further troubleshooting

**WARNING**: **DO NOT ENABLE FOR CUSTOMERS**.GitLab does not retain input and output data unless customers provide consent through a [GitLab Support Ticket](https://docs.gitlab.com/ee/user/gitlab_duo/data_usage.html#:~:text=GitLab%20does%20not%20retain%20input%20and%20output%20data%20unless%20customers%20provide%20consent%20through%20a%20GitLab%20Support%20Ticket.).

We do allow the option to enable enhanced ai logging by enabling the `expanded_ai_logging` feature flag. The flag will allow you to see input and ouput of any of the following AI tools.

To enable expanded AI logging, access the `#production` Slack channel and run the following command.

```
/chatops run features set expanded_ai_logging --user=<USERNAME>
```

After the the `expanded_ai_logging` feature flag is enabled for a user, you view the user input and LLM output for any the GitLab Duo Chat requests made by the user.
