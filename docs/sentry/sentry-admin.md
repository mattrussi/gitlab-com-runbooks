# Sentry general admin troubleshooting

This runbook covers some application errors people might run into while using Sentry, and end up getting escalated to Infra because there's no clear owner for Sentry.

**It is assumed that you have _Owner_ or _Admin_ access in Sentry. If you don't, ask someone who does have that access to grant it to you.**

## "Your authentication credentials are invalid. Please check your project settings."

This error might occur when someone is trying to create or link a GitLab issue with a Sentry issue. If only one Sentry project is impacted, it's very likely going to be the token used for the legacy Sentry to Gitlab integration expiring.

1. Take a look at the existing issues in the project (you may need to add yourself to the project) and see if any of them have linked GitLab issues. We're looking for issues that were _created_ via the Sentry integration. For example, [this GitLab issue](https://gitlab.com/gitlab-org/gitlab/-/issues/331326) was created by `@jobbot` for [this Sentry issue](https://sentry.gitlab.net/gitlab/gitlabcom/issues/1803552/). This tells us that we used jobbot's account to link the Sentry project to a GitLab project.
1. Log into `GitLab.com` as the user from the previous step, and create a new Access Token with `api` scoped permissions under the [Access Tokens page](https://gitlab.com/-/profile/personal_access_tokens).
1. On the project page, go to **Settings > GitLab** (under Legacy Integrations).
1. Replace the existing API token with the one you just created. Save.
1. Test auth by attempting to link a Sentry issue with a GitLab issue: on the Sentry issue page, there'll be a link under **Linked Issues**. If you can get the dialog to show instead of the above error, congrats, you fixed it!
