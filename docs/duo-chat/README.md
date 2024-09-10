# Duo Chat Runbook

## Table of Contents

- [Overview](#overview)
- [Quick Links](#quick-links)
- [Duo Chat Error Codes](#types-of-duo-chat-errors)
- [Further troubleshooting](#further-troubleshooting)
- [Tracing Llm Logs](#tracing-request-logs-from-gitlab-rails-to-the-ai-gateway)

## Overview

When you encounter a Duo Chat error code, it is not always clear where the error comes from and which team is responsible. The following runbook should give any GitLab team member a quick start guide for debugging Duo Chat errors.

## Quick Links

- [Anthropic API Status Page](https://status.anthropic.com/)
- [AI Gateway Grafana Dashboard](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1)

### Logs

Log links for various environments can be found [here](../logging#quick-start).

Different deployments use different indexes. The following indexes are most helpful when debugging Duo Chat:

- AI Gateway logs are in the `pubsub-mlops-inf-gprd-*` index
- GitLab Rails Sidekiq logs are in the `pubsub-sidekiq-inf-gprd*` index
  - When searching this index, filtering on `json.subcomponent : "llm"` ensures only LLM logs are returned
- GitLab Rails logs are in the `pubsub-rails-inf-gprd-*` index

Chat GraphQL request logs for a user can be found with the following Kibana query in the Rails (`pubsub-rails-inf-gprd-*`) index:

> `json.meta.user : "your-gitlab-username" and json.meta.caller_id : "graphql:chat"`

If you find requests for a user there but do not find any results for them using a Kibana query in the Sidekiq (`pubsub-sidekiq-inf-gprd*`) index:

> ``json.meta.user : "username-that-received-error" and json.subcomponent : "llm"`

That probably indicates a problem with Sidekiq where the job is not being kicked off. Check the `#incident-management` to see if there are any ongoing Sidekiq issues. Chat relies on Sidekiq and should be considered "down" if Sidekiq is backed up. See [Duo Chat does not respond or responds very slowly](#duo-chat-does-not-respond-or-responds-very-slowly) below.


### Extra Kibana links

You can find other helpful log searches by looking at saved Kibana objects with the [`group::ai_framework` tag](https://log.gprd.gitlab.net/app/management/kibana/objects).

- [AI Gateway error rates and response statuses](https://log.gprd.gitlab.net/app/dashboards#/view/5f334d60-cfd7-11ee-bc6b-0b206b291ea1?_g=h@2294574)
- [AI Gateway Error Rate](https://log.gprd.gitlab.net/app/dashboards#/view/52e09bf4-a739-4686-9bb3-2f6bf1d69cab?_g=h@2294574)

## Types of Duo Chat Errors

All of GitLab Duo Chat error codes are documented [here](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/user/gitlab_duo_chat/troubleshooting.md#the-gitlab-duo-chat-button-is-not-displayed). The error code prefix letter can help you choose which Kibana logs to search.

### Error Code Layer Identifier

| Code | Layer           |
|------|-----------------|
| M    | Monolith - A network communication error in the monolith layer.     |
| G    | AI Gateway - A data formatting/processing error in the AI gateway layer.     |
| A    | Third-party API - An authentication or data access permissions error in a third-party API.|

### Debugging Error Codes A1000-6000

When you receive an error code starting with 'A', there's an error coming from the AI Gateway.

This can mean that the AI Gateway service itself is erroring or that a third-party LLM provider is returning an error to the AI Gateway.

1. Check for any ongoing outages with our third-party LLM providers:
   - [Anthropic API Status](https://status.anthropic.com/)
   - [Google Cloud Platform Status](https://status.cloud.google.com/)
1. Use the [Grafana Dashboard](https://dashboards.gitlab.net/d/ai-gateway-main/ai-gateway3a-overview?orgId=1) to determine the overall impact. The `Aggregated Service Level Indicators (𝙎𝙇𝙄𝙨)` metric on that page indicates what percentage of users/requests are encountering errors.
1. Track down the specific error
   - Search for any Chat requests with errors for the user in the Sidekiq logs (`pubsub-sidekiq-inf-gprd-*`): `json.meta.user : "username-that-received-error" and json.subcomponent : "llm" and json.error : *`. The log line with the `json.error` value that matches what the user is seeing is what you want to use. Copy the `json.correlation_id` value.
   - Search for the request in the AI Gateway logs (`pubsub-mlops-inf-gprd-*`): `json.jsonPayload.correlation_id : "correlation_id-from-last-result"`
   - The `json.payload.Message` value in the AI Gateway log results should indicate what error message we are receiving from Anthropic, if any.

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

### Duo Chat does not respond or responds very slowly
This could be caused by an issue with Sidekiq queues getting backed up.
First, check the [GitLab status page](https://status.gitlab.com/) to see if there are any reported problems with Sidekiq or "background job processing".
Then, ceck [this dashboard](https://log.gprd.gitlab.net/app/dashboards#/view/3684dc90-73f6-11ee-ac5b-8f88ebd04638). If you see that 'scheduling time for the completion worker' and 'duration time for the completion worker' values are much higher than normal, it indicates the Sidekiq backup may be the problem.


### Tracing request logs from GitLab Rails to the AI Gateway

We utilize a `correlation_id` attribute to track and correlate log entries across both our Rails application and AIGW environments. This unique identifier serves as a key to tie together logs for different systems and components.

With a `correlation_id` from GitLab Rails or Sidekiq logs, you can find the same request in the AI Gateway:

- Access the `pubsub-mlops-inf-gprd-*` index:
- Filter for the logs with `json.jsonPayload.correlation_id : <correlation_id`
- _optional_: Click on the expanded logs icon and select "Surrounding documents" to view logs within relative same time stamp.

## Further troubleshooting

**WARNING**: **DO NOT ENABLE FOR CUSTOMERS**.
GitLab does not retain input and output data unless customers provide consent through a [GitLab Support Ticket](https://docs.gitlab.com/ee/user/gitlab_duo/data_usage.html#:~:text=GitLab%20does%20not%20retain%20input%20and%20output%20data%20unless%20customers%20provide%20consent%20through%20a%20GitLab%20Support%20Ticket.).

We do allow the option to enable enhanced ai logging by enabling the `expanded_ai_logging` feature flag. The flag will allow you to see input and ouput of any of the following AI tools.

To enable expanded AI logging, access the `#production` Slack channel and run the following command.

```
/chatops run feature set --user=$USERNAME expanded_ai_logging true
```

After the the `expanded_ai_logging` feature flag is enabled for a user, you view the user input and LLM output for any the GitLab Duo Chat requests made by the user.
