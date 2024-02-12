# How GitLab.com uses Mailgun

## Sending Mail

The application is provided credentials to use authenticated SMTP to deliver outbound email to Mailgun. These values are defined in [the helm charts for GitLab.com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com).

- [GitLab SMTP Documentation](https://docs.gitlab.com/omnibus/settings/smtp.html)

## Receiving Mail

Incoming email is processed by a Mailroom service that connects to an IMAP account to downloading incoming email and process it. The credentials for this are also defined in [the helm charts for GitLab.com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com).

- [GitLab Incoming Mail Documentation](https://docs.gitlab.com/ee/administration/incoming_email.html)

## Receiving Send Failure Data

When mails are denied or delayed, Mailgun will attempt to notify GitLab.com via a webhook. The GitLab.com instance relies on a secure key to verify webhook calls are from Mailgun. Unverified requests are sent a 404. These responses allow GitLab.com to stop sending emails to bad addresses that are refusing mail.

- [GitLab Mailgun Webhook Documentation](https://docs.gitlab.com/ee/administration/integration/mailgun.html)

## Mailgun Exporter

There is a Mailgun exporter that is used to [generate Mailgun metrics](https://dashboards.gitlab.net/d/mailgun-main/mailgun3a-overview?orgId=1). This has a dedicated API key that it uses to make Mailgun data scrapable.

# How CustomersDot uses Mailgun

TBD
