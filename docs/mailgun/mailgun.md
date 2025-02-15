# How GitLab.com uses Mailgun

**Table of Contents**

[TOC]

## Configuring a domain

When configuring a new domain in Mailgun, it is important to configure all of the appropriate DNS records and sending domains in Mailgun's system.

Depending on the features that are required from Mailgun, the configuration will be different. Using example.com as an example:

### Email tracking feature

When using Mailgun's email tracking feature, the following is required:

Mailgun domains:

- example.com
- email.example.com

DNS:

- TXT example.com -> DKIM record
- TXT example.com -> SPF record
- MX example.com -> mxa.mailgun.org
- MX example.com -> mxb.mailgun.org
- CNAME email.example.com -> mailgun.org

**Important**: You _must_ configure an additional sending domain in Mailgun for `email.example.com` when this CNAME is created. This is important as otherwise a malicious user could add the domain in their account, and this domain will already have valid MX records pointing back to Mailgun (because mailgun.org contains the same MX records). This would potentially allow them to receive email from this GitLab owned domain. When adding this additional sending domain, DO NOT add any additional DNS records for it, we are only configuring this in Mailgun to prevent other parties from claiming it.

If the email tracking feature is not required, simply do not create the associated CNAME, and registering the additional email.example.com domain is not required. The requirements are then:

Mailgun domains:

- example.com

DNS:

- TXT example.com -> DKIM record
- TXT example.com -> SPF record
- MX example.com -> mxa.mailgun.org
- MX example.com -> mxb.mailgun.org

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
