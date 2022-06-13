# Feature Flags

We use [feature flags](https://docs.gitlab.com/ee/operations/feature_flags.html) extensively during GitLab development to allow us to do more controlled testing of new features, as well as revert quickly in the case of an incident. We control feature flags via GitLab chatops in Slack. We have an [issue template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md) prepared in the gitlab-or/gitlab project with regards to rolling out a new feature flag.

## Introduction to feature flags used for development of Gitlab (not feature flags as a Gitlab product)

https://gitlab.com/gitlab-com/Product/-/issues/1460#note_403050265

## Reverting Feature Flags

Should you need to disable a feature flag during an incident, the preferred method is to use chatops and set the flag to false.

```
/chatops run feature set <feature-flag-name> false
```
