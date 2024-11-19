<!-- Permit linking to GitLab docs and issues -->
<!-- markdownlint-disable MD034 -->
# GitLab Code Suggestion Failover Solution

This page provides instructions for switching the LLM provider in case of an outage with the primary provider. It is intended for product and support engineers troubleshooting LLM provider outages affecting **gitlab.com** users.

---

**Table of Contents**

[TOC]

---

## How to switch to backup for code generation

Currently the primary LLM is [claude-3-5-sonnet-20240620 provided by vertex_ai](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/ai_gateway/prompts/definitions/code_suggestions/generations/vertex.yml), and the backup LLM is [claude-3-5-sonnet-20240620 provided by anthropic](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/ai_gateway/prompts/definitions/code_suggestions/generations/base.yml).

We are using environment variables to decide which LLM to use. Here is [the example .env file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/example.env?ref_type=heads). We can see this line in the file:

```
AIGW_DEFAULT_PROMPTS='{"code_suggestions/generations": "vertex"}'
```

This setting will direct LLM request to `claude-3-5-sonnet-20240620` provided by vertex_ai.

In case an outage happens to vertex_ai, we need to update it to:

```
AIGW_DEFAULT_PROMPTS='{"code_suggestions/generations": "base"}'
```

This setting will direct LLM request to `claude-3-5-sonnet-20240620` provided by anthropic.

In .runway folder, there are [env-staging.yml](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.runway/env-production.yml?ref_type=heads) and [env-production.yml](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.runway/env-staging.yml?ref_type=heads). In case of the outage, we need to create and merge the MR to update the AIGW_DEFAULT_PROMPTS, and then the runway tool will apply the .env change.

After the primary LLM provider is back online, we can revert the above MR, so that we are switching back to the primary LLM provider.

## How to switch to backup for code completion

Currently the primary LLM are [code-gecko002 and codestral@2405 provided by vertex_ai](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/code_suggestions/tasks/code_completion.rb#L40), and the backup is [claude-3-5-sonnet-20240620 provided by anthropic](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/code_suggestions/prompts/code_completion/anthropic.rb).

We are using a [feature flag](https://gitlab.com/gitlab-org/gitlab/-/issues/501503) to control whether to enable the failover solution.

To enable failover solution in production when the primary LLM is down, send this to #production slack channel:

```
/chatops run feature set incident_fail_over_completion_provider true
```

After the primary LLM provider is back online, we can disable the feature flag, so that we are switching back to the primary LLM provider:

```
/chatops run feature set incident_fail_over_completion_provider false
```

## How to verify

* Go to [Kibana](https://log.gprd.gitlab.net/app/home#/) Analytics -> Discover
* select `pubsub-mlops-inf-gprod-*` as Data views from the top left
* For code generation, search for `json.jsonPayload.message: "Executing code generation with prompt registry"`, and then we can find the name that is currently in use, eg:
![kibana code gen logs](img/aigw_code_gen_log.png)
  * if you see `json.jsonPayload.prompt_model_class: RunnableBinding`, then we are using `claude-3-5-sonnet-20240620` provided by `vertex_ai`
  * if you see `json.jsonPayload.prompt_model_class: ChatAnthropic`, then we are using `claude-3-5-sonnet-20240620` provided by `anthropic`
* For code completion, search for `json.jsonPayload.message: "code completion input:"`, and then we can find the name that is currently in use, eg:
![kibana code completion logs](img/aigw_code_completion_log.png)
  * if you see `json.jsonPayload.model_provider: anthropic`, then we are using the failover model `claude-3-5-sonnet-20240620` provided by `anthropic`
  * if you see another value for `json.jsonPayload.model_provider`, then we are using a non-failover model
