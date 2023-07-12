# Incidents

General documentation about our incident workflow itself. Service-specific
information, including what to do in response to an incident relating to that
service, is found in the docs for that service.

## Slack `/incident declare` failed to create an incident issue

Usually we rely on the `/incident declare` Slack command to co-ordinate our
incident workflow, including opening an incident issue. If gitlab.com is totally
down, this will fail.

### Create a Google doc

- Navigate to <https://drive.google.com/>
- Create a new Google Doc
- Click "Share" in the top-right corner
- In the "Get link" section of the modal, click "Change link to GitLab" to make
  the doc shareable with the whole company.
- Change the "Anyone with the link in GitLab" permissions to "Editor"
- Click done.
- Post a link to the doc in Slack
- Good luck!

### Rename the incident channel

After an incident is declared, the incident channel is renamed to so it corresponds to the incident issue number (i.e., for issue number `1111` the channel is renamed from `#incident-1234567890` `#incident-1111`).

If GitLab.com is unavailable or if there is a temporary failure the incident issue may be created outside of `/incident declare`.
In this case, you might want to rename the initial incident channel (e.g., `#incident-1234567890`) manually.
To do this issue the following command:

```
curl \
  -H 'Content-Type: application/json; charset=utf-8' \
  -H 'Authorization: Bearer <bearer token>' \
  -X POST https://slack.com/api/conversations.rename \
  -d '{"channel": "<channel ID>", "name": "incident-XXXXX"}'
```

- `<channel ID>`: is the channel ID of the channel you wish to rename. To find this, click the channel in Slack and scroll to the bottom where you will see `Channel ID: <id>`.
- `<bearer token>`: `SLACK_BOT_ACCESS_TOKEN` in [woodhouse CI variables](https://ops.gitlab.net/gitlab-com/gl-infra/woodhouse/-/settings/ci_cd).
- `incident-XXXXX` is the new name of the channel.
